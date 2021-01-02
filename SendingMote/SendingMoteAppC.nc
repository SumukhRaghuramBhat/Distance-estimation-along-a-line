
#include "RssiDemoMessages.h"
//#include "printf.h"

configuration SendingMoteAppC {
} implementation {
  components ActiveMessageC, MainC, LedsC;  
  components new AMSenderC(AM_RSSIMSG) as RssiMsgSender;
  components new TimerMilliC() as SendTimer;
  components SendingMoteC as App;


  App.Boot -> MainC;
  App.SendTimer -> SendTimer;
  App.RssiMsgSend -> RssiMsgSender;
  App.RadioControl -> ActiveMessageC;
  App.Leds -> LedsC;


}
