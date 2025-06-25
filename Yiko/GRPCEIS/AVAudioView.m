//
//  AVAudioView.m
//  GRPCEIS
//
//  Created by le tong on 2023/12/15.
//

#import "AVAudioView.h"


@implementation AVAudioView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.label];
        [self addSubview:self.btn];
        [self addSubview:self.endBtn];
        [self addSubview:self.PlayBtn];
        [self addSubview:self.transBtn];
        [self addSubview:self.receivePlayBtn];
        
    }
    return self;
}

- (UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc]initWithFrame:CGRectMake(100, 100, 200, 30)];
        _label.text = @"label11";
        _label.textColor = [UIColor redColor];
    }
    return _label;
}

- (UIButton *)btn{
    if (!_btn) {
        _btn = [[UIButton alloc]initWithFrame:CGRectMake(50, 200, 50, 30)];
        [_btn setTitle:@"录音" forState:UIControlStateNormal];
        [_btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _btn;
}
- (UIButton *)endBtn{
    if (!_endBtn) {
        _endBtn = [[UIButton alloc]initWithFrame:CGRectMake(150, 200, 50, 30)];
        [_endBtn setTitle:@"结束" forState:UIControlStateNormal];
        [_endBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _endBtn;
}
- (UIButton *)PlayBtn{
    if (!_PlayBtn) {
        _PlayBtn = [[UIButton alloc]initWithFrame:CGRectMake(250, 200, 50, 30)];
        [_PlayBtn setTitle:@"播放" forState:UIControlStateNormal];
        [_PlayBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _PlayBtn;
}
- (UIButton *)transBtn{
    if (!_transBtn) {
        _transBtn = [[UIButton alloc]initWithFrame:CGRectMake(50, 300, 100, 30)];
        [_transBtn setTitle:@"语音发送" forState:UIControlStateNormal];
        [_transBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _transBtn;
}

- (UIButton *)receivePlayBtn{
    if (!_receivePlayBtn) {
        _receivePlayBtn = [[UIButton alloc]initWithFrame:CGRectMake(200, 300, 100, 30)];
        [_receivePlayBtn setTitle:@"语音播放" forState:UIControlStateNormal];
        [_receivePlayBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
    return _receivePlayBtn;
}


@end
