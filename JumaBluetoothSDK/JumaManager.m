//
//  JumaManager.m
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/7/16.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "JumaManager.h"
#import "JumaManagerConstant.h"
#import "JumaManager+Internal.h"

#import "JumaInternalDevice.h"
#import "JumaDeviceConstant.h"
#import "JumaConfig.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "NSArray+Block.h"
#import "NSError+Juma.h"

@interface JumaManager () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;

/** @[ JumaInternalDevice ] */
@property (nonatomic, strong) NSMutableArray *devices;

@end

@implementation JumaManager

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
- (instancetype)initWithDelegate:(id<JumaManagerDelegate>)delegate queue:(dispatch_queue_t)queue options:(NSDictionary *)options {
    self = [super init];
    if (!self) { return nil; }
    
    options = [JumaManager validInitOptionsFromDict:options];
    
    _devices = [NSMutableArray array];
    _delegate = delegate;
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
    return self;
}
#endif

#pragma mark - setter and getter

- (JumaManagerState)state {

    switch (_centralManager.state) {
        case CBCentralManagerStatePoweredOn:    return JumaManagerStatePoweredOn;
        case CBCentralManagerStatePoweredOff:   return JumaManagerStatePoweredOff;
        case CBCentralManagerStateUnauthorized: return JumaManagerStateUnauthorized;
        case CBCentralManagerStateUnsupported:  return JumaManagerStateUnsupported;
        case CBCentralManagerStateResetting:    return JumaManagerStateResetting;
        case CBCentralManagerStateUnknown:      return JumaManagerStateUnknown;
    }
}

- (BOOL)isScanning {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    return _centralManager.isScanning;
#else
    return [[_centralManager valueForKey:@"isScanning"] boolValue];
#endif
}

#pragma mark - public method
- (JumaDevice *)retrieveDeviceWithUUID:(NSString *)UUID {
    
    if (UUID) {
        
        // search array
        JumaInternalDevice *device = [_devices juma_detect:^BOOL(JumaInternalDevice *object) {
            return [object.peripheral.identifier.UUIDString isEqualToString:UUID];
        }];
        
        // retrieve discovered peripheral
        if (!device) {
            NSArray *identififer = [NSArray arrayWithObjects:[[NSUUID alloc] initWithUUIDString:UUID], nil];
            CBPeripheral *p = [_centralManager retrievePeripheralsWithIdentifiers:identififer].firstObject;
            device = [JumaInternalDevice deviceWithPeripheral:p manager:self];
        }
        
        // retrieve connected peripheral
        if (!device) {
            NSArray *peripherals = [_centralManager retrieveConnectedPeripheralsWithServices:[JumaDeviceConstant services]];
            CBPeripheral *p = [peripherals juma_detect:^BOOL(CBPeripheral *object) {
                return [object.identifier.UUIDString isEqualToString:UUID];
            }];
            device = [JumaInternalDevice deviceWithPeripheral:p manager:self];
        }
        
        if (device && (![_devices containsObject:device])) {
            [_devices addObject:device];
        }
        return device;
    }
    return nil;
}


- (void)scanForDeviceWithOptions:(NSDictionary *)options {
    
    options = [JumaManager validScanOptionsFromDict:options];
    
    if (_centralManager.state == CBCentralManagerStatePoweredOn) {
        
        // 开启扫描
        NSDictionary *scanOptions = [JumaManager validScanOptionsFromDict:options];
        [_centralManager scanForPeripheralsWithServices:@[ [CBUUID UUIDWithString:@"FE90"] ] options:scanOptions];
        
        // 绝对不能删除, 需要保持同一个 UUID 的 JumaDevice 的地址不变
//        [self.devices removeAllObjects];
    }
}

- (void)stopScan {
    
    [_centralManager stopScan];
    
    if ([self.delegate respondsToSelector:@selector(managerDidStopScan:)]) {
        [self.delegate managerDidStopScan:self];
    }
}

- (void)connectDevice:(JumaDevice *)device {
    
    NSParameterAssert(device != nil);
    
    NSAssert([device isKindOfClass:[JumaInternalDevice class]], @"Invalid device: %@", device);
    
    JumaInternalDevice *temp = (JumaInternalDevice *)device;
    NSAssert(temp.peripheral, @"Invalid device: %@", device);
    
    [_centralManager connectPeripheral:temp.peripheral options:nil];
    [temp connectedByManager];
}

- (void)disconnectDevice:(JumaDevice *)device {
    
    NSParameterAssert(device != nil);
    
    NSAssert([device isKindOfClass:[JumaInternalDevice class]], @"Invalid device: %@", device);
    
    JumaInternalDevice *temp = (JumaInternalDevice *)device;
    CBPeripheral *p = temp.peripheral;
    NSAssert(p, @"Invalid device: %@", device);
    
    if (p.state == CBPeripheralStateConnected) {
        for (CBService *service in p.services) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if (characteristic.isNotifying) {
                    [p setNotifyValue:NO forCharacteristic:characteristic]; // 关闭通知功能
                }
            }
        }
    }
    [_centralManager cancelPeripheralConnection:p];
    [temp disconnectedByManager];
}

- (JumaInternalDevice *)deviceInArrayWithPeripheral:(CBPeripheral * const)p {
    
    for (JumaInternalDevice *device in _devices) {
        if (device.peripheral == p) {
            return device;
        }
    }
    return nil;
}

- (void)sendDelegateFailToConnect:(JumaDevice *)device error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(manager:didFailToConnectDevice:error:)]) {
        [self.delegate manager:self didFailToConnectDevice:device error:error];
    }
}

- (void)sendDelegateDisconnect:(JumaDevice *)device error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(manager:didDisconnectDevice:error:)]) {
        [self.delegate manager:self didDisconnectDevice:device error:error];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    
    peripherals = [peripherals juma_map:^JumaDevice *(CBPeripheral *object) {
        return [JumaInternalDevice deviceWithPeripheral:object manager:self];
    }];
    
    self.devices = peripherals.mutableCopy;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if ([self.delegate respondsToSelector:@selector(managerDidUpdateState:)]) {
        [self.delegate managerDidUpdateState:self];
    }
    
    // 必须删除
    if (central.state < CBCentralManagerStatePoweredOff) {
        [_devices removeAllObjects];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    JumaInternalDevice *device = [self deviceInArrayWithPeripheral:peripheral];
    
    if (!device) {
        
        device = [JumaInternalDevice deviceWithPeripheral:peripheral manager:self];
        if (device) {
            [_devices addObject:device];
        }
        else {
            JMLog(@"初始化 JumaInternalDevice 对象失败");
        }
    }
    
    if (device.peripheral) {
        device.advertisementData = advertisementData;
        if ([self.delegate respondsToSelector:@selector(manager:didDiscoverDevice:RSSI:)]) {
            [self.delegate manager:self didDiscoverDevice:device RSSI:RSSI];
        }
    }
    else {
        JMLog(@"%s, device.peripheral == nil", __func__);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    //JMLog(@"%s, %@, %@", __func__, peripheral, error);
    
    JumaInternalDevice *device = [self deviceInArrayWithPeripheral:peripheral];
    [self sendDelegateFailToConnect:device error:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    //JMLog(@"%s, %@, %@", __func__, peripheral, error);
    
    JumaInternalDevice *device = [self deviceInArrayWithPeripheral:peripheral];
    [device didDisconnectedByManager];
    
    // 如果成功开启 peripheral 的 notify 功能, 并且 peripheral 已经在 JUMA 注册过
    // 则 JumaManager 通知 delegate 连接成功, 否则向 delegate 通知连接失败
    // JumaManager 通知 delegate 连接成功之后, 如果连接断开, 则 JumaManager 通知 delegate 连接断开
    
    
    // 可以连接这个 device, 通知 delegate 连接断开
    if (device.canEstablishConnection)
    {
        [self sendDelegateDisconnect:device error:error];
    }
    // 不可以连接这个 device, 通知 delegate 连接失败
    else
    {
        error = device.canNotEstablishConnectionError ?: error;
        [self sendDelegateFailToConnect:device error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    //JMLog(@"%s, %@", __func__, peripheral);
    
    JumaInternalDevice *device = [self deviceInArrayWithPeripheral:peripheral];
    [device didConnectedByManager];
}

@end
