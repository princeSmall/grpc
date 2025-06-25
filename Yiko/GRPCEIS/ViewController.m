//
//  ViewController.m
//  GRPCEIS
//
//  Created by le tong on 2023/12/5.
//

#import "ViewController.h"
#import <GRPCEIS/EisNew.pbrpc.h>
#import <GRPCEIS/EisNew.pbobjc.h>
#import <GRPCClient/GRPCTransport.h>
#import <RxLibrary/GRXWriter.h>
#import <RxLibrary/GRXWriter+Immediate.h>
#import "AVAudioView.h"
#import <AVFoundation/AVFoundation.h>

@interface ResponseHandler : NSObject<GRPCProtoResponseHandler>
@property (nonatomic, strong) NSMutableData *audioData;
@end

@implementation ResponseHandler

- (dispatch_queue_t)dispatchQueue {
    return dispatch_get_main_queue();
}

- (void)didReceiveProtoMessage:(GPBMessage *)message {
    NSLog(@"%@", message);
    GetInteractResponse *res = (GetInteractResponse *)message;
    NSLog(@"%@", res.recognitionText);
    if ([res.responseType isEqualToString:@"tts"]) {
        if (res.isFinal) {
            [self base64ToData:self.audioData];
        }else{
            [self.audioData appendData:res.recognitionAudio];
        }
    }
    if ([res.responseType isEqualToString:@"nlp"] && ![res.nlpResponse.sentence isEqualToString:@"EVENT_APP_WAKE_UP"]) {
        Answer *ans= res.nlpResponse.answerArray[0];
        NSString *text = ans.text;
        NSLog(@"%@",text);
        [[NSNotificationCenter defaultCenter]postNotificationName:@"msg" object:text userInfo:nil];
    }
}
- (void)base64ToData:(NSData *)base64Data{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"audio.mp3"];
    NSLog(@"----%@",urlStr);
    [base64Data writeToFile:urlStr atomically:YES];
}

- (NSMutableData *)audioData{
    if (!_audioData) {
        _audioData = [NSMutableData data];
    }
    return _audioData;
}

@end

@interface ViewController()<AVAudioRecorderDelegate,UITextFieldDelegate>

@property (nonatomic, strong) AVAudioView *avView;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;//音频播放器，用于播放录音文件
@property (nonatomic, strong) AVAudioPlayer *audioPlayer2;//音频播放器，用于播放录音文件
@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) UITextField *field;
@property (nonatomic, strong) UIButton *receivePlayBtn;
@property (nonatomic, strong) UILabel *msgLable;
//@property (nonatomic, strong) UITextin;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.avView = [[AVAudioView alloc]initWithFrame:CGRectMake(0, 300, self.view.bounds.size.width, 400)];
    self.avView.layer.borderWidth =  1;
    [self.avView.btn addTarget:self action:@selector(startRecorder) forControlEvents:UIControlEventTouchUpInside];
    
    [self.avView.endBtn addTarget:self action:@selector(endRecorder) forControlEvents:UIControlEventTouchUpInside];
    
    [self.avView.PlayBtn addTarget:self action:@selector(playAudio) forControlEvents:UIControlEventTouchUpInside];
    
    [self.avView.transBtn addTarget:self action:@selector(sendAudio) forControlEvents:UIControlEventTouchUpInside];

    [self.avView.receivePlayBtn addTarget:self action:@selector(playReceiveAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.avView];
    [self.view addSubview:self.field];
    [self.view addSubview:self.receivePlayBtn];
    [self setAudioSession];
    [self.view addSubview:self.msgLable];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateMsgLabel:) name:@"msg" object:nil];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self sendMessage:@"EVENT_APP_WAKE_UP" isAudio:false];
}
- (void)updateMsgLabel:(NSNotification *)fication{
    NSString *msg = fication.object;
    self.msgLable.text = msg;
    NSLog(@"%@",msg);
}

- (UILabel *)msgLable{
    if (!_msgLable) {
        _msgLable = [[UILabel alloc]initWithFrame:CGRectMake(10, 180, self.view.bounds.size.width - 20, 100)];
        _msgLable.text = @"文字回复";
        _msgLable.textAlignment = NSTextAlignmentLeft;
        _msgLable.numberOfLines = 2;
    }
    return _msgLable;
}

- (UIButton *)receivePlayBtn{
    if (!_receivePlayBtn) {
        _receivePlayBtn = [[UIButton alloc]initWithFrame:CGRectMake(200, 250, 100, 30)];
        [_receivePlayBtn setTitle:@"文字发送" forState:UIControlStateNormal];
        [_receivePlayBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_receivePlayBtn addTarget:self action:@selector(sendTextMsg) forControlEvents:UIControlEventTouchUpInside];
    }
    return _receivePlayBtn;
}
- (UITextField *)field {
    if (!_field) {
        _field = [[UITextField alloc]initWithFrame:CGRectMake(10, 30, self.view.bounds.size.width - 20, 140)];
        _field.delegate = self;
        _field.textColor = [UIColor blackColor];
        _field.font = [UIFont systemFontOfSize:13];
        _field.layer.borderWidth = 1;
        
        _field.placeholder = @"请输入文本";
    }
    return _field;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)sendTextMsg{
    NSString *msg = self.field.text;
    [self sendMessage:msg isAudio:false];
}

- (void)sendAudio{
    self.avView.label.text = @"音频发送完成";
    [self sendMessage:nil isAudio:true];
}



/**
 *  设置音频会话
 */
-(void)setAudioSession{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}


/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
-(AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}
/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
-(NSURL *)getSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"Record.wav"];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}


/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    //用的有kAudioFormatLinearPCM会将未压缩的音频流写入到文件中，这种格式的保真度最高，不过相应文件也最大，kAudioFormatAppleIMA4、kAudioFormatMPEG4AAC等会显著缩小文件，还能保证相对较高的音频质量。
    
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}
/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
    NSLog(@"录音完成!");
}


- (NSURL *)getCurrentVideo{
    NSString *file = [[NSBundle mainBundle] pathForResource:@"currVideo" ofType:@"wav"];
    NSURL *fileUrl = [NSURL URLWithString:file];
    return fileUrl;
}
/**
 *  创建播放器
 *
 *  @return 播放器
 */
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSURL *url=[self getSavePath];
        NSError *error=nil;
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        _audioPlayer.numberOfLoops = 0;
        [_audioPlayer setVolume:100.0];
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}
-(AVAudioPlayer *)audioPlayer2{
    if (!_audioPlayer2) {
        NSURL *url=[self getMpSavePath];
        NSError *error=nil;
        _audioPlayer2 =[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        _audioPlayer2.numberOfLoops = 0;
        [_audioPlayer2 setVolume:100.0];
        [_audioPlayer2 prepareToPlay];
        if (error) {
            NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer2;
}

-(NSURL *)getMpSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"audio.mp3"];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

- (void)playReceiveAudio{
    self.avView.label.text = @"接受音频播放中";
    [self.audioPlayer2 play];
}

- (void)playAudio{
    self.avView.label.text = @"播放音频中";
    [self.audioPlayer play];
}

- (void)startRecorder{
    if ([self.audioRecorder isRecording]) {
        return;
    }
    self.avView.label.text = @"正在录制音频";
    [self.audioRecorder record];
}

- (void)endRecorder{
    if ([self.audioRecorder isRecording]) {
        self.avView.label.text = @"录制音频完成";
        [self.audioRecorder stop];
    }
}

- (void)sendMessage:(NSString *)msg isAudio:(BOOL)isAudio{
    EIService *service = [[EIService alloc]initWithHost:@"eis-nlp.dc-cn.cn.ecouser.net:443"];
    
    GRPCMutableCallOptions *options = [[GRPCMutableCallOptions alloc] init];
    // this example does not use TLS (secure channel); use insecure channel instead
    options.transport = GRPCDefaultTransportImplList.core_secure;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"beta.ecouser.net" ofType:@"cert"];
    NSError *error;
    NSString *cert = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    options.PEMRootCertificates = cert;
    
    GRPCStreamingProtoCall *call = [service getInteractWithResponseHandler:[[ResponseHandler alloc]init] callOptions:options ];
    [call start];
    if (isAudio) {
        [call writeMessage:[self messageRequest:nil type:@"text"]];
        [call writeMessage:[self messageVideo]];
    }else {
        if ([msg isEqualToString:@"EVENT_APP_WAKE_UP"]) {
            [call writeMessage:[self messageRequest:@"EVENT_APP_WAKE_UP" type:@"event"]];
        }else{
            [call writeMessage:[self messageRequest:msg type:@"text"]];
        } 
    }
}
- (GetInteractRequest *)messageVideo{
    GetInteractRequest *request = [GetInteractRequest message];
    AudioParams *params = [AudioParams new];
    params.sampleRate = 16000;
    params.audioType = AudioType_Wav;
    params.channels = 1;
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"Record.wav"];
    NSData *curData = [NSData dataWithContentsOfFile:urlStr];
    params.audio =curData;
    params.sampleBytes = 2;
    params.isFinal = true;
    request.audioParams = params;
    return request;
}

- (GetInteractRequest *)messageRequest:(NSString *)sentence type:(NSString *)type{
    
    GetInteractRequest *request = [GetInteractRequest message];
    TextParams *params = [TextParams new];
    params.chatBotId = @"yiko_full_stack";
    params.userId = @"ffqhdvpd102c6d0a";
    params.language = @"zh-cn";
    params.state = @"unknown";
    params.command = @"";
    params.from = @"APP";
    params.appUserId = @"ffqhdvpd102c6d0a";
    BotInfo *info = [BotInfo new];
    info.botId = @"ffqhdvpd102c6d0a";
    params.botInfo = info;
    params.params = @"";

    AppInfo *appInfo = [AppInfo new];
    appInfo.homeId = @"64f812685258644f81f8e1fd";
    appInfo.userId = @"ffqhdvpd102c6d0a";
    appInfo.authorization = @"Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJjIjoiNWZlMWE0MWQxZmU5OGUwNjE5NTc2ODk5IiwidSI6ImZmcWhkdnBkMTAyYzZkMGEiLCJyIjoiR0xCZDJkYTNiY0c2IiwidCI6ImEiLCJpYXQiOjE3MDM2NzQ2ODUsImV4cCI6MTcwNDI3OTQ4NX0.u53izjU4X4jGo67nmT_R8juDXg6G2NsFMToRCGnI8pCgm4H9LG0uXV4IN1w6khHx8Wf9CxMU7tgfo5a0DkeJHsmCpCQZLIP3qbs2oGlnktnK8QnkPiOmA1kWMJwuDZN0pNrk35XdUwvRBw2QVRDDEhNsctJPE8XmuJWP6oFmtdE";
    params.appInfo = appInfo;
    params.dataVersion = 1.0;
    params.sessionId = @"1";
    params.roundId = @"1";
    params.fwVersion = @"";
    params.networkStatus = YES;
    params.tone = @"599417bd01b86c";
    params.connectTimeout = 60;
    params.enableTimeoutCallback = 60;
    params.serverTimeout = 60;
    params.sentence = sentence;
    params.type = type;
    params.opType = sentence ? OpType_NlpTts : OpType_AsrNlpTts;
    request.textParams = params;
    return request;
}



/**
 
 - (NSData *)getRecorderDataFromURL:(NSURL *)url{
 
 NSMutableData *data = [[NSMutableData alloc]init];     //用于保存音频数据
 AVAsset *asset = [AVAsset assetWithURL:url];
 NSError *error;
 AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error]; //创建读取
 if (!reader) {
 NSLog(@"%@",[error localizedDescription]);
 }
 AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//从媒体中得到声音轨道
 //读取配置
 NSDictionary *dic   = @{AVFormatIDKey            :@(kAudioFormatLinearPCM),
 AVLinearPCMIsBigEndianKey:@NO,
 AVLinearPCMIsFloatKey    :@NO,
 AVLinearPCMBitDepthKey   :@(16)
 };
 //读取输出，在相应的轨道和输出对应格式的数据
 AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
 //赋给读取并开启读取
 [reader addOutput:output];
 [reader startReading];
 while (reader.status == AVAssetReaderStatusReading) {
 
 CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
 if (sampleBuffer) {
 
 CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
 size_t length = CMBlockBufferGetDataLength(blockBUfferRef);   //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
 SInt16 sampleBytes[length];
 CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
 [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
 CMSampleBufferInvalidate(sampleBuffer);  //销毁
 CFRelease(sampleBuffer);                 //释放
 }
 }
 
 if (reader.status == AVAssetReaderStatusCompleted) {
 
 self.audioData = data;
 
 }else{
 
 NSLog(@"获取音频数据失败");
 return nil;
 }
 return data;
 
 }
 
 */


@end
