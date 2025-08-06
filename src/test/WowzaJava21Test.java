package test;

import com.wowza.wms.amf.*;
import com.wowza.wms.application.*;
import com.wowza.wms.client.*;
import com.wowza.wms.logging.WMSLogger;
import com.wowza.wms.logging.WMSLoggerFactory;
import com.wowza.wms.logging.WMSLoggerIDs;
import com.wowza.wms.module.*;
import com.wowza.wms.request.*;
import com.wowza.wms.server.Server;
import com.wowza.wms.stream.publish.Stream;

public class WowzaJava21Test extends ModuleBase {

    private static final WMSLogger logger = WMSLoggerFactory.getLogger(WowzaJava21Test.class);

    // Modern Java record
    public record ModuleInfo(String name, int version) {
    }

    public void onAppStart(IApplicationInstance appInstance) {

        // Text block
        var info = """
                Wowza + Java 21 Test Module
                Application: %s
                Java Version: %d
                Status: Compatible
                """.formatted(appInstance.getName(), Runtime.version().feature());

        logger.info(info);

        // Pattern matching and switch expression
        Object testObj = appInstance.getName();
        var result = switch (testObj) {
            case String s when s.equals("live") -> "Live streaming application";
            case String s -> "Application: " + s;
            default -> "Unknown application type";
        };

        logger.info("Application type: " + result);

        // Record usage
        var moduleInfo = new ModuleInfo("RTMP Auth", 21);
        logger.info("Module: " + moduleInfo.name() + " v" + moduleInfo.version());
    }
}
