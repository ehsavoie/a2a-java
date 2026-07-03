package org.a2aproject.example.helloworld.orchestrator;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import dev.langchain4j.agent.tool.Tool;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class LocalTools {

    @Tool("Returns the current date and time")
    String getCurrentDateTime() {
        return LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
    }
}
