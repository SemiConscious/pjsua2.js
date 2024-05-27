#ifndef __CALLBACK_HPP__
#define __CALLBACK_HPP__

#include "pjsua2.hpp"
using namespace pj;

#define CB_TYPE(fun) std::function<void(On ## fun ## Param &)>
#define CB_TYPERET(fun,ret) std::function<ret(On ## fun ## Param &)>
#define CB_TYPESPEC(prm) std::function<void(prm &)>
#define CB_TYPEVOID std::function<void(void)>

// default callback implementation. Parent callback is not const, no return value
#define CB_IMPL(fun) CB_TYPE(fun) on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPE(fun) fn) { on ## fun ## CBFn = fn; } \
virtual void on ## fun(On ## fun ## Param &prm) { if (on ## fun ## CBFn) { on ## fun ##CBFn(prm); } }

// same as default except parent expects a return value
#define CB_IMPLRETTYPE(fun,ret,def) CB_TYPERET(fun,ret) on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPERET(fun,ret) fn) { on ## fun ## CBFn = fn; } \
virtual ret on ## fun(On ## fun ## Param &prm) { if (on ## fun ## CBFn) { return on ## fun ##CBFn(prm); } return def; }

// same as default except the parent callback sends a const parameter. We const_cast<> this to non-const
// as the qualifier is discarded anyway in JS, and ThreadSafeFunction cannot deal with consts
#define CB_IMPLCONST(fun) CB_TYPE(fun) on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPE(fun) fn) { on ## fun ## CBFn = fn; } \
virtual void on ## fun(const On ## fun ## Param &prm) { if (on ## fun ## CBFn) { on ## fun ##CBFn(const_cast<On ## fun ## Param &>(prm)); } }

// same as default but the type of the parent parameter is different
#define CB_IMPLTYPESPEC(fun,type) CB_TYPESPEC(type) on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPESPEC(type) fn) { on ## fun ## CBFn = fn; } \
virtual void on ## fun(type &prm) { if (on ## fun ## CBFn) { on ## fun ## CBFn(prm); } }

// callback function is void/void
#define CB_IMPLTYPEVOID(fun) CB_TYPEVOID on ## fun ## CBFn; \
void set ## fun ## CB(CB_TYPEVOID fn) { on ## fun ## CBFn = fn; } \
virtual void on ## fun() { if (on ## fun ## CBFn) { on ## fun ## CBFn(); } }

#define DESTRUCT(fun) if (on ## fun ## CBFn) { on ## fun ## CBFn = nullptr; on ## fun ## CBFn = 0; }

class AccountCB: public Account {
    public:
    void destroy() {
        DESTRUCT(IncomingCall)
        DESTRUCT(RegStarted)
        DESTRUCT(RegState)
        DESTRUCT(IncomingSubscribe)
        DESTRUCT(InstantMessage)
        DESTRUCT(InstantMessageStatus)
        DESTRUCT(TypingIndication)
        DESTRUCT(MwiInfo)
    }
    ~AccountCB() {
        destroy();
    }
    CB_IMPL(IncomingCall)
    CB_IMPL(RegStarted)
    CB_IMPL(RegState)
    CB_IMPL(IncomingSubscribe)
    CB_IMPL(InstantMessage)
    CB_IMPL(InstantMessageStatus)
    CB_IMPL(TypingIndication)
    CB_IMPL(MwiInfo)
};

class EndpointCB: public Endpoint {
 public:
    void destroy() {
        DESTRUCT(NatDetectionComplete)
        DESTRUCT(NatCheckStunServersComplete)
        DESTRUCT(TransportState)
        DESTRUCT(Timer)
        DESTRUCT(SelectAccount)
        DESTRUCT(IpChangeProgress)
        DESTRUCT(MediaEvent)
        DESTRUCT(CredAuth)
        DESTRUCT(RejectedIncomingCall)
    }
    ~EndpointCB() {
        destroy();
    }
    CB_IMPLCONST(NatDetectionComplete)
    CB_IMPLCONST(NatCheckStunServersComplete)
    CB_IMPLCONST(TransportState)
    CB_IMPLCONST(Timer)
    CB_IMPL(SelectAccount)
    CB_IMPL(IpChangeProgress)
    CB_IMPL(MediaEvent)
    CB_IMPLRETTYPE(CredAuth,pj_status_t,0)
    CB_IMPL(RejectedIncomingCall)
};

class CallCB: public Call {
 public:
    CallCB(Account &acc, int call_id):
    Call(acc, call_id) 
    {}
    void destroy() {
        DESTRUCT(CallState)
        DESTRUCT(CallTsxState)
        DESTRUCT(CallMediaState)
        DESTRUCT(CallSdpCreated)
        DESTRUCT(StreamPreCreate)
        DESTRUCT(StreamCreated)
        DESTRUCT(StreamDestroyed)
        DESTRUCT(DtmfDigit)
        DESTRUCT(DtmfEvent)
        DESTRUCT(CallTransferRequest)
        DESTRUCT(CallTransferStatus)
        DESTRUCT(CallReplaceRequest)
        DESTRUCT(CallReplaced)
        DESTRUCT(CallRxOffer)
        DESTRUCT(CallRxReinvite)
        DESTRUCT(CallTxOffer)
        DESTRUCT(InstantMessage)
        DESTRUCT(InstantMessageStatus)
        DESTRUCT(TypingIndication)
        DESTRUCT(CallRedirected)
        DESTRUCT(CallMediaTransportState)
        DESTRUCT(CallMediaEvent)
        DESTRUCT(CreateMediaTransport)
        DESTRUCT(CreateMediaTransportSrtp)
    }
    ~CallCB() {
        destroy();
    }
    CB_IMPL(CallState)
    CB_IMPL(CallTsxState)
    CB_IMPL(CallMediaState)
    CB_IMPL(CallSdpCreated)
    CB_IMPL(StreamPreCreate)
    CB_IMPL(StreamCreated)
    CB_IMPL(StreamDestroyed)
    CB_IMPL(DtmfDigit)
    CB_IMPL(DtmfEvent)
    CB_IMPL(CallTransferRequest)
    CB_IMPL(CallTransferStatus)
    CB_IMPL(CallReplaceRequest)
    CB_IMPL(CallReplaced)
    CB_IMPL(CallRxOffer)
    CB_IMPL(CallRxReinvite)
    CB_IMPL(CallTxOffer)
    CB_IMPL(InstantMessage)
    CB_IMPL(InstantMessageStatus)
    CB_IMPL(TypingIndication)
    CB_IMPLRETTYPE(CallRedirected,pjsip_redirect_op,PJSIP_REDIRECT_ACCEPT)
    CB_IMPL(CallMediaTransportState)
    CB_IMPL(CallMediaEvent)
    CB_IMPL(CreateMediaTransport)
    CB_IMPL(CreateMediaTransportSrtp)
};

class AudioMediaPortCB: public AudioMediaPort {
 public:
    void destroy() {
        DESTRUCT(FrameRequested)
        DESTRUCT(FrameReceived)
    }
    ~AudioMediaPortCB() {
        destroy();
    }
    CB_IMPLTYPESPEC(FrameRequested, MediaFrame)
    CB_IMPLTYPESPEC(FrameReceived, MediaFrame)
};

class AudioMediaPlayerCB: public AudioMediaPlayer {
 public:
    void destroy() {
        DESTRUCT(Eof2)
    }
    ~AudioMediaPlayerCB() {
        destroy();
    }
    CB_IMPLTYPEVOID(Eof2) // void
};

class BuddyCB: public Buddy {
 public:
    void destroy() {
        DESTRUCT(BuddyState)
        DESTRUCT(BuddyEvSubState)
    }
    ~BuddyCB() {
        destroy();
    }
    CB_IMPLTYPEVOID(BuddyState) // void
    CB_IMPL(BuddyEvSubState) // OnBuddyEvSubStateParam
};



#endif