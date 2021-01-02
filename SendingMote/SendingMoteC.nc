
#include "ApplicationDefinitions.h"
#include "RssiDemoMessages.h"
#include "Timer.h"
//#include "printf.h"

module SendingMoteC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as SendTimer;
  uses interface AMSend as RssiMsgSend;
  uses interface SplitControl as RadioControl;

} 

  implementation {
  message_t msg;

  void SendPacket();

  void SentBlink() { 
		call Leds.led1Toggle();
	}

  void FailBlink() { // If a packet Reception over Radio fails, Led0 is toggled
		call Leds.led0Toggle();
	}

  void SuccessBlink() { //// If a packet Reception over Radio is successful, Led2 is toggled
		call Leds.led2Toggle();
	}

  event void Boot.booted(){
    //printf("[BEACON %d] Mote booted...\n", TOS_NODE_ID);
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t result){
    call SendTimer.startPeriodic(SEND_INTERVAL_MS);   
  }

  event void RadioControl.stopDone(error_t result){
}


  event void SendTimer.fired(){

    //printf("[BEACON %d] Broadcasting beacon... \n", TOS_NODE_ID); 
    SendPacket();

  }
  
event void RssiMsgSend.sendDone(message_t *m, error_t error){
   SentBlink();  //calls sent blink function
}

//funtion that sends packets to BS
void SendPacket(){ 
  RssiMsg* pkt = (RssiMsg*) (call RssiMsgSend.getPayload(&msg, sizeof (RssiMsg)));
  pkt->beacon_id = TOS_NODE_ID;
  call RssiMsgSend.send(AM_BROADCAST_ADDR, &msg, sizeof(RssiMsg));
  SuccessBlink();
}
}
