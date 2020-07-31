//
//  RCDAudioFrameObserver.h
//  Pods
//
//  Created by SHU on 7/29/20.
//

#ifndef RCDAudioFrameObserver_h
#define RCDAudioFrameObserver_h

#import <AgoraRtcEngineKit/IAgoraMediaEngine.h>
#import <UIKit/UIKit.h>
#import <stdio.h>
#import "AgoraAudioFrameObserver.h"

//实现一个 IAudioFrameObserver 类
class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
    public:
        // 获取录制的音频帧
        virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
        {
            return true;
        }
        // 获取播放的音频帧
        virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
        {
            return true;
         }
        // 获取远端某个用户发送的音频帧
        virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
         {
            return true;
         }
        // 获取本地录制和播放混音后的音频帧
        virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override
         {
         return true;
         }

};

static AgoraAudioFrameObserver* s_audioFrameObserver;
void addRegiset(AgoraRtcEngineKit *agoraKit) {

    // Agora Engine of C++
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)agoraKit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);

    if (mediaEngine) {
        s_audioFrameObserver = new AgoraAudioFrameObserver();
        mediaEngine->registerAudioFrameObserver(s_audioFrameObserver);
    }
}

- (void)cancelRegiset {
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)self.agoraKit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    mediaEngine->registerAudioFrameObserver(NULL);
}

#endif /* RCDAudioFrameObserver_h */
