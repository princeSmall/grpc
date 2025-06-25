//
//  AVAudioView.h
//  GRPCEIS
//
//  Created by le tong on 2023/12/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioView : UIView

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *btn;
@property (nonatomic, strong) UIButton *endBtn;
@property (nonatomic, strong) UIButton *PlayBtn;
@property (nonatomic, strong) UIButton *receivePlayBtn;
@property (nonatomic, strong) UIButton *transBtn;
@end

NS_ASSUME_NONNULL_END
