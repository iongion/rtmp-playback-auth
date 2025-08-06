package com.wowza.wms.plugin.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.wowza.wms.application.IApplicationInstance;
import com.wowza.wms.application.IApplication;
import com.wowza.wms.vhost.IVHost;
import com.wowza.wms.application.WMSProperties;
import com.wowza.wms.client.IClient;
import com.wowza.wms.request.RequestFunction;
import com.wowza.wms.amf.AMFDataList;
import com.wowza.wms.amf.AMFDataObj;

import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class ModuleRTMPPlaybackAuthenticationTest {

    @InjectMocks
    private ModuleRTMPPlaybackAuthentication module;

    @Mock
    private IApplicationInstance appInstance;
    @Mock
    private IApplication app;
    @Mock
    private IVHost vhost;
    @Mock
    private WMSProperties appProperties;
    @Mock
    private IClient client;
    @Mock
    private WMSProperties clientProperties;
    @Mock
    private RequestFunction function;

    @TempDir
    Path tempDir;

    private Path passwordFile;

    @BeforeEach
    void setUp() throws IOException {
        when(appInstance.getVHost()).thenReturn(vhost);
        when(appInstance.getApplication()).thenReturn(app);
        when(vhost.getHomePath()).thenReturn(tempDir.toString());
        when(app.getName()).thenReturn("myApp");

        Path confAppDir = tempDir.resolve("conf").resolve("myApp");
        Files.createDirectories(confAppDir);
        passwordFile = confAppDir.resolve("publish.password");
        try (BufferedWriter writer = Files.newBufferedWriter(passwordFile)) {
            writer.write("user1:pass1\n");
            writer.write("user2 pass2\n");
            writer.write("# This is a comment\n");
        }

        when(appInstance.getProperties()).thenReturn(appProperties);
        when(client.getProperties()).thenReturn(clientProperties);
        when(client.getIp()).thenReturn("192.168.0.1");
        when(appProperties.getPropertyBoolean(anyString(), anyBoolean())).thenReturn(true);
        when(appProperties.getPropertyInt(anyString(), anyInt())).thenReturn(5000);
        when(appProperties.getPropertyStr("securityPublishPasswordFile")).thenReturn("");
    }

    @Test
    void loadCredentials_ShouldLoadCorrectUsers() {
        module.onAppStart(appInstance);
        Map<String, String> creds = module.getLoadedCredentials();
        assertEquals(2, creds.size(), "Should load exactly 2 users");
        assertEquals("pass1", creds.get("user1"));
        assertEquals("pass2", creds.get("user2"));
    }

    @Test
    void onConnect_WithValidCredentials_ObjParams_AcceptsConnection() {
        module.onAppStart(appInstance);

        AMFDataObj cred = new AMFDataObj();
        cred.put("username", "user1");
        cred.put("password", "pass1");
        AMFDataList params = new AMFDataList();
        params.add(new AMFDataObj());
        params.add(cred);

        module.onConnect(client, function, params);

        verify(client, never()).rejectConnection(anyString());
        verify(clientProperties).setProperty("authenticated", true);
        verify(clientProperties).setProperty("username", "user1");
    }

    @Test
    void onConnect_WithValidCredentials_StringParams_AcceptsConnection() {
        module.onAppStart(appInstance);

        AMFDataList params = new AMFDataList();
        params.add(new AMFDataObj());
        params.add("user2");
        params.add("pass2");

        module.onConnect(client, function, params);

        verify(client, never()).rejectConnection(anyString());
        verify(clientProperties).setProperty("authenticated", true);
    }

    @Test
    void onConnect_MissingCredentials_RejectsConnection() {
        module.onAppStart(appInstance);

        AMFDataList params = new AMFDataList();
        params.add(new AMFDataObj());

        module.onConnect(client, function, params);

        verify(client).rejectConnection(anyString());
    }

    @Test
    void userExistsAndReloadCredentials_WorksAsExpected() throws IOException {
        module.onAppStart(appInstance);
        assertTrue(module.userExists("user1"));
        try (BufferedWriter writer = Files.newBufferedWriter(passwordFile)) {
            writer.write("newUser newPass\n");
        }
        assertFalse(module.userExists("newUser"));
        module.reloadCredentials();
        assertTrue(module.userExists("newUser"));
    }

    @Test
    void getPasswordFilePath_DefaultAndCustomBehavior() {
        module.onAppStart(appInstance);
        String defaultPath = module.getPasswordFilePath();
        assertEquals(
                tempDir.resolve("conf").resolve("myApp").resolve("publish.password").toString(),
                defaultPath);

        when(appProperties.getPropertyStr("securityPublishPasswordFile")).thenReturn("/etc/custom.pwd");
        module.onAppStart(appInstance);
        assertEquals("/etc/custom.pwd", module.getPasswordFilePath());
    }

    @Test
    void getAuthStats_IncludesLoadedCountAndFilePath() {
        module.onAppStart(appInstance);
        String stats = module.getAuthStats();
        assertTrue(stats.contains("Loaded users: 2"));
        assertTrue(stats.contains("Password file:"));
    }
}
