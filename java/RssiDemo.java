
import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class RssiDemo implements MessageListener {

  private MoteIF moteIF;
  
  public RssiDemo(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new RssiMsg(), this);
  }
    
  public void messageReceived(int to, Message message) {
    RssiMsg msg = (RssiMsg) message;
    int source = message.getSerialPacket().get_header_src();
    System.out.println("Rssi Message received from node " + msg.get_beacon_id() + 
		       ": Rssi = " +  msg.get_rssi() + ": Distance = " +  msg.get_dist() + ": 
           Position = " +  msg.get_mse());
  }
  
  private static void usage() {
    System.err.println("usage: RssiDemo [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	usage();
	System.exit(1);
      }
      source = args[1];
    }
    else if (args.length != 0) {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }

    MoteIF mif = new MoteIF(phoenix);
    RssiDemo serial = new RssiDemo(mif);
  }


}
