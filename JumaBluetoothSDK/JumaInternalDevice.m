//
//  JumaInternalDevice.m
//  JumaBluetoothSDK
//
//  Created by 汪安军 on 15/7/22.
//  Copyright (c) 2015年 JUMA. All rights reserved.
//

#import "JumaInternalDevice.h"
#import "JumaDevice+UUIDConstants.h"
#import "JumaDevice+DelegateEventNotifying.h"
#import "JumaManager.h"
#import "JumaConfig.h"
#import "JumaDataSender.h"

#import "NSData+Category.h"
#import "NSError+Juma.h"

@import CoreBluetooth;

@interface JumaInternalDevice () <CBPeripheralDelegate>
{
    JumaDeviceState _state;
}

@property (nonatomic, readwrite) BOOL canEstablishConnection;
@property (nonatomic, strong, readwrite) NSError *canNotEstablishConnectionError;

@property (nonatomic, weak) JumaManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;


/** 发通知的 characteristic */
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;
/** 写入时有  response 的 characteristic, 用于写入包含类型信息的数据 */
@property (nonatomic, strong) CBCharacteristic *commandCharacteristic;
/** 写入时没有 response 的 characteristic, 用于写入不包含类型信息的数据 */
@property (nonatomic, strong) CBCharacteristic *bulkOutCharacteristic;


//@property (nonatomic, copy) JumaWriteDataBlock writeDataHandler;
@property (nonatomic, copy) JumaUpdateFirmwareBlock updateFirmwareHandler;
@property (nonatomic, copy) JumaReadRssiBlock readRssiHandler;


/** 向 peripheral 发送大数据的发送器 */
@property (nonatomic, strong) JumaDataSender *dataSender;

@end

@implementation JumaInternalDevice

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral manager:(JumaManager *)manager {
    NSParameterAssert(peripheral != nil);
    NSParameterAssert(manager != nil);
    
    self = [super init];
    if (!self) { return nil; }
    
    _manager = manager;
    _peripheral = peripheral;
    _peripheral.delegate = self;
    return self;
}

+ (instancetype)deviceWithPeripheral:(CBPeripheral *)peripheral manager:(JumaManager *)manager {
    return [[self alloc] initWithPeripheral:peripheral manager:manager];
}

#pragma mark - setter and getter

- (NSString *)UUID {
    return _peripheral.identifier.UUIDString;
}

- (NSString *)name {
    NSString *name = _peripheral.name;
    NSString *localName = self.advertisementData[CBAdvertisementDataLocalNameKey];
    
    // http://beantalk.punchthrough.com/t/update-ios-ble-gatt-cache-or-clear/2325
    if (localName && ![name isEqualToString:localName]) {
        name = localName;
    }
    
    return name;
}

- (JumaDeviceState)state {
    return _state;
}

#pragma mark - public method

- (void)connectedByManager {
    self.canEstablishConnection = NO;
    self.canNotEstablishConnectionError = nil;
    _state = JumaDeviceStateConnecting;
}

- (void)didConnectedByManager {
    [_peripheral discoverServices:[JumaDevice services]];
}

- (void)disconnectedByManager {
    _state = JumaDeviceStateDisconnected;
}

- (void)didDisconnectedByManager {
    
    _state = JumaDeviceStateDisconnected;
    self.readRssiHandler = nil;
//    self.writeDataHandler = nil;
    self.updateFirmwareHandler = nil;
    self.dataSender = nil;
    self.notifyCharacteristic = nil;
    self.commandCharacteristic = nil;
    self.bulkOutCharacteristic = nil;
}

- (void)disconnectFromManager {
    [_manager disconnectDevice:self];
}

- (void)readRSSI {
    [_peripheral readRSSI];
}

- (void)readRSSI:(JumaReadRssiBlock)handler {
    self.readRssiHandler = handler;
    [self readRSSI];
}

- (void)writeData:(NSData *)data type:(UInt8)typeCode {
    
    NSParameterAssert(data != nil);
    NSParameterAssert(data.length < 199);
    NSParameterAssert(typeCode < 128);
    
    [self sendOperationWithDataType:typeCode implementation:^{
        
        self.dataSender = [[JumaDataSender alloc] initWithData:data type:typeCode];
        
        // 发送第一个数据
        [_dataSender sendFirstDataToCharacteristic:_commandCharacteristic
                                        peripheral:_peripheral];
    }];
}

- (void)setOtaMode {
    char bytes[] = { 'O', 'T', 'A', '_', 'M', 'O', 'D', 'E', 0 };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)]; // <4f54415f 4d4f4445 00>
    
    [self sendOperationWithDataType:JumaDataType82 implementation:^{
        
        self.dataSender = [[JumaDataSender alloc] initWithData:data type:JumaDataType82];
        [_dataSender sendFirstDataToCharacteristic:_commandCharacteristic peripheral:_peripheral];
    }];
}

- (void)updateFirmware:(NSData *)firmwareData {
    
    NSParameterAssert(firmwareData != nil);
    
    [self sendOperationWithDataType:JumaDataType81 implementation:^{
        
        self.dataSender = [[JumaDataSender alloc] initWithData:firmwareData  type:JumaDataType81];
        
        // 发送 OTA Begin 标识, 准备进行固件升级
        [_dataSender sendOtaBeginToCharacteristic:_commandCharacteristic
                                       peripheral:_peripheral];
    }];
}

- (void)updateFirmware:(NSData *)firmwareData completionHandler:(JumaUpdateFirmwareBlock)handler {
    
    self.updateFirmwareHandler = handler;
    [self updateFirmware:firmwareData];
}

- (void)readDeviceID {
    const JumaDataType type = JumaDataTypeReadDeviceID;
    
    [self sendOperationWithDataType:type implementation:^{
        self.dataSender = [[JumaDataSender alloc] initWithData:nil type:type];
        [self.dataSender sendFirstDataToCharacteristic:self.commandCharacteristic peripheral:self.peripheral];
    }];
}

- (void)readVendorIDAndProductID {
    const JumaDataType type = JumaDataTypeReadVerdorIDAndProductID;
    
    [self sendOperationWithDataType:type implementation:^{
        self.dataSender = [[JumaDataSender alloc] initWithData:nil type:type];
        [self.dataSender sendFirstDataToCharacteristic:self.commandCharacteristic peripheral:self.peripheral];
    }];
}

- (void)readFirmwareVersion {
    const JumaDataType type = JumaDataTypeReadFirmwareVersion;
    
    [self sendOperationWithDataType:type implementation:^{
        self.dataSender = [[JumaDataSender alloc] initWithData:nil type:type];
        [self.dataSender sendFirstDataToCharacteristic:self.commandCharacteristic peripheral:self.peripheral];
    }];
}

- (void)modifyVendorID:(NSData *)vendorID productID:(NSData *)productID {
    NSParameterAssert(vendorID.length == 4);
    NSParameterAssert(productID.length == 4);
    
    const JumaDataType type = JumaDataTypeModifyVerdorIDAndProductID;
    
    NSMutableData *data = [NSMutableData dataWithData:vendorID];
    [data appendData:productID];
    
    [self sendOperationWithDataType:type implementation:^{
        self.dataSender = [[JumaDataSender alloc] initWithData:data type:type];
        [self.dataSender sendFirstDataToCharacteristic:self.commandCharacteristic peripheral:self.peripheral];
    }];
}

#pragma mark - private method

- (void)didEstablishConnection {
    
    self.canEstablishConnection = YES;
    _state = JumaDeviceStateConnected;
    if ([_manager.delegate respondsToSelector:@selector(manager:didConnectDevice:)]) {
        [_manager.delegate manager:_manager didConnectDevice:self];
    }
}

- (void)sendOperationWithDataType:(JumaDataType)type implementation:(void (^)(void))handler {
    
    if (_peripheral.state == CBPeripheralStateConnected)
    {
        if (_commandCharacteristic && _bulkOutCharacteristic)
        {
            // 在上一个数据发送完之前, 不允许再发送新的数据
            if (!_dataSender)
            {
                handler();
            }
            else
            {
                NSError *error = [NSError juma_errorWithDescription:@"The last data transfer is not completed."];
                [self outputError:error dataType:type];
            }
        }
        else
        {
            NSError *error = [NSError juma_errorWithDescription:@"Unknow error"];
            [self outputError:error dataType:type];
            
            // 断开连接
            [self disconnectFromManager];
        }
    }
    else
    {
        NSDictionary *info = @{ NSLocalizedDescriptionKey : @"The specified device is not connected." };
        NSError *error = [NSError errorWithDomain:CBErrorDomain code:CBErrorNotConnected userInfo:info];
        [self outputError:error dataType:type];
    }
}

- (void)outputError:(NSError *)error dataType:(const JumaDataType)type {
    
    if (type == JumaDataType81) {
        [self notifyDelegateWithUpdatingFirmwareError:error];
    } else {
        [self notifyDelegateWithWritingError:error];
    }
}

#pragma mark - CBPeripheralDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    [self notifyDelegateWithRSSI:(error ? nil : RSSI) error:error];
}
#else
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    [self notifyDelegateWithRSSI:(error ? nil : peripheral.RSSI) error:error];
}
#endif

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    //JMLog(@"%s, %@, %@", __func__, peripheral, error);
    
    if (!error)
    {
        for (CBService *service in peripheral.services) {
            
            if ([service.UUID isEqual: [JumaDevice serviceUUID]]) {
                
                [peripheral discoverCharacteristics:[JumaDevice characteristics] forService:service];
                return;
            }
        }
        
        NSString *desc = [NSString stringWithFormat:@"The device named %@ is not supported by JUMA", peripheral.name];
        self.canNotEstablishConnectionError = [NSError juma_errorWithDescription:desc];
        [_manager disconnectDevice:self];
    }
    else
    {
        self.canNotEstablishConnectionError = error;
        [_manager disconnectDevice:self];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    //JMLog(@"%s, %@, %@, %@", __func__, peripheral, service, error);
    
    if (!error)
    {
        CBUUID *notifyUUID  = [JumaDevice notifyCharacteristicUUID];
        CBUUID *commandUUID = [JumaDevice commandCharacteristicUUID];
        CBUUID *bulkOutUUID = [JumaDevice bulkOutCharacteristicUUID];
        
        self.commandCharacteristic = nil;
        self.notifyCharacteristic  = nil;
        self.bulkOutCharacteristic = nil;
        
        for (CBCharacteristic *c in service.characteristics)
        {
            CBUUID *UUID = c.UUID;
            
            if (     [UUID isEqual: notifyUUID])  { self.notifyCharacteristic  = c; } // 发出通知
            else if ([UUID isEqual: commandUUID]) { self.commandCharacteristic = c; } // 写入包含类型信息的数据
            else if ([UUID isEqual: bulkOutUUID]) { self.bulkOutCharacteristic = c; } // 写入不包含类型信息的数据
        }
        
        if (_notifyCharacteristic && _commandCharacteristic && _bulkOutCharacteristic)
        {
            [peripheral setNotifyValue:YES forCharacteristic:_notifyCharacteristic];
        }
        else
        {
            NSString *desc = [NSString stringWithFormat:@"The device named %@ is not supported by JUMA", peripheral.name];
            self.canNotEstablishConnectionError = [NSError juma_errorWithDescription:desc];
            [_manager disconnectDevice:self];
        }
    }
    else
    {
        self.canNotEstablishConnectionError = error;
        [_manager disconnectDevice:self];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    JMLog(@"%s, %@, %@, %@, %@", __func__, peripheral, characteristic, error, [NSThread currentThread]);
    
    if ([characteristic.UUID isEqual: [JumaDevice notifyCharacteristicUUID]])
    {
        if (!error)
        {
            if (characteristic.isNotifying)
            {
                [self didEstablishConnection];
            }
            else
            {
                NSString *desc = [NSString stringWithFormat:@"The device named %@ can not notify temporarily", peripheral.name];
                self.canNotEstablishConnectionError = [NSError juma_errorWithDescription:desc];
                [_manager disconnectDevice:self];
            }
        }
        else
        {
            self.canNotEstablishConnectionError = error;
            [_manager disconnectDevice:self];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //    JMLog(@"%s, %@, %@, %@", __func__, peripheral, characteristic, error);
    
    if (![characteristic.UUID isEqual: [JumaDevice commandCharacteristicUUID]]) { return; }
    
    // 数据的类型是固件
    if (_dataSender.dataType == JumaDataType81) {
        
        if (error) {
            self.dataSender = nil;
            [self notifyDelegateWithUpdatingFirmwareError:error];
            [_manager disconnectDevice:self];
            return;
        }
        
        if (_dataSender.didWriteAllFirmwareData) {
            //JMLog(@"did write OTA_End. Update firmware successfully.");
            self.dataSender = nil;
            [self notifyDelegateWithUpdatingFirmwareError:nil];
            return;
        }
        
        [_dataSender sendRemainingRowsToCharacteristic:_bulkOutCharacteristic
                                            peripheral:peripheral];
    }
    // 其他 type
    else {
        
        if (error) {
            // 数据发送失败, 清除保存的发送器
            self.dataSender = nil;
            [self notifyDelegateWithWritingError:error];
            [_manager disconnectDevice:self];
            return;
        }
        
        [_dataSender sendRemainingDatasToCharacteristic:_bulkOutCharacteristic
                                             peripheral:peripheral];
        
        // 数据发送完毕之后, 清除保存的发送器, 为下一次发送做准备
        self.dataSender = nil;
        [self notifyDelegateWithWritingError:nil];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //JMLog(@"%s, %@, %@, %@", __func__, peripheral, characteristic, error);
    
    if (![characteristic.UUID isEqual: [JumaDevice notifyCharacteristicUUID]]) { return; }
    
    NSData *receivedData = characteristic.value;
    
    // 数据的类型是固件
    if (_dataSender && _dataSender.dataType == JumaDataType81) {
        
        if (error) {
            self.dataSender = nil;
            [self notifyDelegateWithUpdatingFirmwareError:error];
            [_manager disconnectDevice:self];
            return;
        }
        
        // 根据 peripheral 回应的数据来发送相应的固件数据
        [_dataSender sendFirstRowforResponse:receivedData
                              characteristic:_commandCharacteristic
                                  peripheral:peripheral];
    }
    else {
        // error 发生的时候, 不可能知道区分 error 的 data type
        // 存在不需要先发送命令也能发数据到手机的情况, 此时 error 也不能区分 data type
        if (error) {
            [self notifyDelegateWithUpdatedData:nil type:JumaDataTypeError error:error];
            [_manager disconnectDevice:self];
            return;
        }
        
        // 类型
        JumaDataType foo = 0;
        [receivedData getBytes:&foo length:sizeof(foo)];
        const JumaDataType type = foo;
        
        // 内容
        NSData *content = receivedData.length > 2 ? [receivedData juma_subdataFromIndex:2] : nil;
        
        if (type <= JumaDataTypeUserMax) {
            [self notifyDelegateWithUpdatedData:content type:(char)type error:nil];
            return;
        }
        
        switch (type) {
            case JumaDataTypeUserMax: {
                break;
            }
            case JumaDataTypeReadDeviceID: {
                [self notifyDelegateWithDeviceID:content error:error];
                break;
            }
            case JumaDataType81: {
                break;
            }
            case JumaDataType82: {
                break;
            }
            case JumaDataTypeReadVerdorIDAndProductID: {
                [self notifyDelegateWithVendorIdAndProductIdData:content error:error];
                break;
            }
            case JumaDataTypeReadFirmwareVersion: {
                [self notifyDelegateWithFirmwareVersion:content error:error];
                break;
            }
            case JumaDataTypeModifyVerdorIDAndProductID: {
                [self notifyDelegateVerdorIdAndProductIdModified:content error:error];
                break;
            }
        }
    }
}

#pragma mark - Override from JumaDevice+DelegateEventNotifying

- (void)notifyDelegateWithRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    if (_readRssiHandler) {
        _readRssiHandler(RSSI, error);
        self.readRssiHandler = nil;
    } else {
        [super notifyDelegateWithRSSI:RSSI error:error];
    }
}

- (void)notifyDelegateWithUpdatingFirmwareError:(NSError *)error {
    
    if (_updateFirmwareHandler) {
        _updateFirmwareHandler(error);
        self.updateFirmwareHandler = nil;
    } else {
        [super notifyDelegateWithUpdatingFirmwareError:error];
    }
}

@end
