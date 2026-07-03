package org.a2aproject.example.helloworld.orchestrator;

import dev.langchain4j.agentic.declarative.A2AClientAgent;
import dev.langchain4j.agentic.declarative.A2AClientCustomizer;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Tracer;
import jakarta.enterprise.inject.spi.CDI;
import java.util.HashMap;
import java.util.Map;
import org.a2aproject.sdk.client.ClientBuilder;
import org.a2aproject.sdk.client.transport.jsonrpc.JSONRPCTransport;
import org.a2aproject.sdk.client.transport.jsonrpc.JSONRPCTransportConfig;

public interface HelloWorldRemoteAgent {

    @A2AClientAgent(
            a2aServerUrl = "http://localhost:9999",
            name = "Hello World Agent (Remote)",
            description = "Sends a name to the remote HelloWorld A2A agent for greeting.",
            outputKey = "greeting")
    @UserMessage("Say hello to {{name}}")
    String greet(@V("name") String name);

    @A2AClientCustomizer
    static void customizer(ClientBuilder cb) {
        Tracer tracerInstance = CDI.current().select(Tracer.class).get();
        OpenTelemetry penTelemetryInstrance = CDI.current().select(OpenTelemetry.class).get();
        JSONRPCTransportConfig transportConfig = new JSONRPCTransportConfig();
        Map<String, Object> parameters = new HashMap<>(transportConfig.getParameters());
        parameters.put("org.a2aproject.sdk.extras.opentelemetry.Tracer", tracerInstance);
        parameters.put("org.a2aproject.sdk.extras.opentelemetry.OpenTelemetry", penTelemetryInstrance);
        transportConfig.setParameters(parameters);
        cb.withTransport(JSONRPCTransport.class, transportConfig);
    }
}
