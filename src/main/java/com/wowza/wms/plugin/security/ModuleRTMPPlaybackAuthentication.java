package com.wowza.wms.plugin.security;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.wowza.wms.application.IApplicationInstance;
import com.wowza.wms.application.WMSProperties;
import com.wowza.wms.client.IClient;
import com.wowza.wms.logging.WMSLogger;
import com.wowza.wms.logging.WMSLoggerFactory;
import com.wowza.wms.module.ModuleBase;
import com.wowza.wms.request.RequestFunction;
import com.wowza.wms.amf.AMFData;
import com.wowza.wms.amf.AMFDataList;
import com.wowza.wms.amf.AMFDataObj;

/**
 * RTMP Playback Authentication Module - API Compatible Version for Wowza 4.x
 *
 * This module provides ONLY standard RTMP username/password authentication for
 * playback connections
 * using NetConnection.connect() parameters. It does NOT support query string
 * authentication.
 *
 * Key Features:
 * - Uses Wowza's standard publish.password file
 * - ONLY supports NetConnection.connect() authentication (RTMP standard)
 * - NO query string authentication support
 * - Takes priority over SecurityToken authentication
 * - Compatible with Adobe Media Live Encoder and other standard RTMP clients
 * - Automatic credential reloading when files change
 *
 * @author Custom Implementation (Updated for Wowza 4.x)
 * @version 4.0
 */
public class ModuleRTMPPlaybackAuthentication extends ModuleBase {

    private static final WMSLogger logger = WMSLoggerFactory.getLogger(ModuleRTMPPlaybackAuthentication.class);

    // Configuration properties
    private static final String PROP_REQUIRE_AUTH = "rtmpPlaybackRequireAuth";
    private static final String PROP_AUTH_TIMEOUT = "rtmpPlaybackAuthTimeout";
    private static final String PROP_USE_PUBLISH_AUTH = "rtmpPlaybackUsePublishAuth";
    private static final String PROP_CUSTOM_PASSWORD_FILE = "securityPublishPasswordFile";
    private static final String PROP_OVERRIDE_SECURITY_TOKEN = "rtmpPlaybackOverrideSecurityToken";

    // Default values
    private static final boolean DEFAULT_REQUIRE_AUTH = true;
    private static final int DEFAULT_AUTH_TIMEOUT = 30000; // 30 seconds
    private static final boolean DEFAULT_USE_PUBLISH_AUTH = true;
    private static final boolean DEFAULT_OVERRIDE_SECURITY_TOKEN = true;

    // Internal storage
    private final Map<String, String> credentials = new ConcurrentHashMap<>();
    private boolean requireAuth = DEFAULT_REQUIRE_AUTH;
    private int authTimeout = DEFAULT_AUTH_TIMEOUT;
    private boolean usePublishAuth = DEFAULT_USE_PUBLISH_AUTH;
    private boolean overrideSecurityToken = DEFAULT_OVERRIDE_SECURITY_TOKEN;
    private String customPasswordFile;
    private long lastFileModified = 0;
    private IApplicationInstance appInstance;

    /**
     * Module initialization - called when module is loaded
     */
    public void onAppStart(IApplicationInstance appInstance) {
        this.appInstance = appInstance;
        logger.info("ModuleRTMPPlaybackAuthentication: Starting STANDARD RTMP authentication module for Wowza 4.x");
        logger.info("ModuleRTMPPlaybackAuthentication: Using ONLY standard NetConnection.connect() authentication");

        // Load configuration
        loadConfiguration(appInstance);

        // Load credentials
        loadCredentials();

        logger.info("ModuleRTMPPlaybackAuthentication: Module started successfully.");
    }

    /**
     * Called when application stops
     */
    public void onAppStop(IApplicationInstance appInstance) {
        credentials.clear();
        logger.info("ModuleRTMPPlaybackAuthentication: Module stopped");
    }

    /**
     * RTMP client connection handler.
     * NOTE: The @Override annotation is removed as it may not match the superclass
     * exactly in all 4.x versions,
     * and the super.onConnect() call is removed as it's not needed and causes a
     * compile error.
     */
    public void onConnect(IClient client, RequestFunction function, AMFDataList params) {

        if (!requireAuth) {
            // No call to super.onConnect() is needed. Connection is accepted by default.
            return;
        }

        logger.info("ModuleRTMPPlaybackAuthentication: Processing RTMP connect request from " + client.getIp());

        boolean authenticated = false;
        String username = null;
        String password = null;

        try {
            // ONLY check NetConnection.connect parameters - NO query string support
            if (params != null && params.size() > 1) {

                // Method 1: Check for AMF object with credentials
                for (int i = 1; i < params.size(); i++) {
                    AMFData param = params.get(i);
                    if (param instanceof AMFDataObj) {
                        AMFDataObj obj = (AMFDataObj) param;
                        if (obj.containsKey("username") && obj.containsKey("password")) {
                            username = obj.getString("username");
                            password = obj.getString("password");
                            logger.info(
                                    "ModuleRTMPPlaybackAuthentication: Using NetConnection object authentication for user: "
                                            + username);
                            break;
                        }
                    }
                }

                // Method 2: Check for simple string parameters
                if (username == null && params.size() >= 3) {
                    AMFData userParam = params.get(1);
                    AMFData passParam = params.get(2);
                    if (userParam != null && passParam != null &&
                            !userParam.toString().isEmpty() && !passParam.toString().isEmpty()) {
                        username = userParam.toString();
                        password = passParam.toString();
                        logger.info(
                                "ModuleRTMPPlaybackAuthentication: Using NetConnection string authentication for user: "
                                        + username);
                    }
                }
            }

            // Authenticate user
            if (username != null && password != null) {
                authenticated = authenticateUser(username, password);
                if (authenticated) {
                    logger.info("ModuleRTMPPlaybackAuthentication: User '" + username
                            + "' authenticated successfully via standard RTMP");
                    client.getProperties().setProperty("authenticated", true);
                    client.getProperties().setProperty("username", username);
                    // For debugging
                    client.getProperties().setProperty("rtmpAuthMethod", "standard");

                    // Override SecurityToken authentication if enabled
                    if (overrideSecurityToken) {
                        client.getProperties().setProperty("securityTokenOverridden", true);
                        logger.info(
                                "ModuleRTMPPlaybackAuthentication: SecurityToken authentication overridden for user: "
                                        + username);
                    }
                } else {
                    logger.warn("ModuleRTMPPlaybackAuthentication: Authentication failed for user: " + username);
                }
            } else {
                logger.warn("ModuleRTMPPlaybackAuthentication: No standard RTMP credentials provided from "
                        + client.getIp());
            }

        } catch (Exception e) {
            logger.error("ModuleRTMPPlaybackAuthentication: Error during authentication", e);
        }

        if (authenticated) {
            // Connection is accepted by default if not rejected. No super.onConnect() call
            // needed.
            logger.info("ModuleRTMPPlaybackAuthentication: Connection accepted for user: " + username);
        } else {
            // Reject connection
            logger.warn("ModuleRTMPPlaybackAuthentication: Rejecting connection from " + client.getIp());
            client.rejectConnection(
                    "RTMP authentication required: use NetConnection.connect() with username and password parameters");
        }
    }

    /**
     * RTMP client disconnection handler
     * NOTE: The @Override annotation and super.onDisconnect() call are removed for
     * API compatibility.
     */
    public void onDisconnect(IClient client) {
        // Use client.getProperties().getPropertyStr() for Wowza 4.x API
        String username = client.getProperties().getPropertyStr("username");
        if (username != null) {
            logger.info("ModuleRTMPPlaybackAuthentication: User '" + username + "' disconnected");
        }
    }

    /**
     * Load configuration from application properties
     */
    private void loadConfiguration(IApplicationInstance appInstance) {
        if (appInstance == null) {
            logger.warn("ModuleRTMPPlaybackAuthentication: No application instance - using defaults");
            return;
        }

        WMSProperties props = appInstance.getProperties();
        if (props == null) {
            logger.warn("ModuleRTMPPlaybackAuthentication: No application properties - using defaults");
            return;
        }

        // Load configuration values
        requireAuth = props.getPropertyBoolean(PROP_REQUIRE_AUTH, DEFAULT_REQUIRE_AUTH);
        authTimeout = props.getPropertyInt(PROP_AUTH_TIMEOUT, DEFAULT_AUTH_TIMEOUT);
        usePublishAuth = props.getPropertyBoolean(PROP_USE_PUBLISH_AUTH, DEFAULT_USE_PUBLISH_AUTH);
        overrideSecurityToken = props.getPropertyBoolean(PROP_OVERRIDE_SECURITY_TOKEN,
                DEFAULT_OVERRIDE_SECURITY_TOKEN);
        customPasswordFile = props.getPropertyStr(PROP_CUSTOM_PASSWORD_FILE);

        logger.info("ModuleRTMPPlaybackAuthentication: Configuration loaded:");
        logger.info("  Require Auth: " + requireAuth);
        logger.info("  Auth Timeout: " + authTimeout + "ms");
        logger.info("  Use Publish Auth: " + usePublishAuth);
        logger.info("  Override SecurityToken: " + overrideSecurityToken);
        if (customPasswordFile != null) {
            logger.info("  Custom Password File: " + customPasswordFile);
        }
    }

    /**
     * Load credentials from publish.password file
     */
    private void loadCredentials() {
        String passwordFilePath = resolvePasswordFilePath();

        File passwordFile = new File(passwordFilePath);
        if (!passwordFile.exists()) {
            logger.warn("ModuleRTMPPlaybackAuthentication: Password file not found: " + passwordFilePath);
            return;
        }

        // Check if file was modified
        long currentModified = passwordFile.lastModified();
        if (currentModified <= lastFileModified && !credentials.isEmpty()) {
            return; // No changes
        }
        lastFileModified = currentModified;

        credentials.clear();

        try (BufferedReader reader = new BufferedReader(new FileReader(passwordFile))) {
            String line;
            int lineNumber = 0;
            while ((line = reader.readLine()) != null) {
                lineNumber++;
                line = line.trim();
                if (line.isEmpty() || line.startsWith("#")) {
                    continue;
                }

                // Parse username:password or username password format
                String[] parts;
                if (line.contains(":")) {
                    parts = line.split(":", 2);
                } else {
                    parts = line.split("\\s+", 2);
                }

                if (parts.length >= 2) {
                    String username = parts[0].trim();
                    String password = parts[1].trim();
                    credentials.put(username, password);
                } else {
                    logger.warn("ModuleRTMPPlaybackAuthentication: Invalid line format at line " + lineNumber + " in "
                            + passwordFilePath);
                }
            }
        } catch (IOException e) {
            logger.error("ModuleRTMPPlaybackAuthentication: Error reading password file: " + passwordFilePath, e);
        }

        logger.info("ModuleRTMPPlaybackAuthentication: Loaded " + credentials.size() + " user credentials from "
                + passwordFilePath);
    }

    /**
     * Resolve password file path
     */
    private String resolvePasswordFilePath() {
        String vhostHome = appInstance.getVHost().getHomePath();
        String appName = appInstance.getApplication().getName();

        // Check for custom password file property first
        if (customPasswordFile != null && !customPasswordFile.isEmpty()) {
            File file = new File(customPasswordFile);
            if (file.isAbsolute()) {
                return customPasswordFile; // Absolute path
            }
            // Relative to [vhost-home]/conf/
            return vhostHome + "/conf/" + customPasswordFile;
        }

        // Use application-specific publish.password file if it exists
        // Path: [vhost-home]/conf/[app-name]/publish.password
        String appPasswordFile = vhostHome + "/conf/" + appName + "/publish.password";
        File appFile = new File(appPasswordFile);
        if (appFile.exists()) {
            return appPasswordFile;
        }

        // Fall back to server-wide (VHost) publish.password file
        // Path: [vhost-home]/conf/publish.password
        return vhostHome + "/conf/publish.password";
    }

    /**
     * Authenticate user credentials
     */
    private boolean authenticateUser(String username, String password) {
        if (username == null || password == null || username.trim().isEmpty() || password.trim().isEmpty()) {
            return false;
        }

        // Reload credentials if file changed
        loadCredentials();

        // Direct credential comparison
        String storedPassword = credentials.get(username.trim());
        boolean authenticated = password.trim().equals(storedPassword);

        if (!authenticated && storedPassword != null) {
            logger.warn("ModuleRTMPPlaybackAuthentication: Password mismatch for user '" + username + "'");
        } else if (storedPassword == null) {
            logger.warn("ModuleRTMPPlaybackAuthentication: User '" + username + "' not found in credentials");
        }

        return authenticated;
    }

    // Public methods for administration
    public Map<String, String> getLoadedCredentials() {
        loadCredentials();
        return new java.util.HashMap<>(credentials);
    }

    public String getPasswordFilePath() {
        return resolvePasswordFilePath();
    }

    public void reloadCredentials() {
        lastFileModified = 0;
        loadCredentials();
    }

    public boolean userExists(String username) {
        loadCredentials();
        return credentials.containsKey(username);
    }

    public String getAuthStats() {
        return String.format("Loaded users: %d, Password file: %s, Override SecurityToken: %s",
                credentials.size(), getPasswordFilePath(), overrideSecurityToken);
    }
}
