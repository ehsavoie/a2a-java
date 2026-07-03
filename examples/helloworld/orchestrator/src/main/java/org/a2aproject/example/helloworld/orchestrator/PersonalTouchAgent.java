package org.a2aproject.example.helloworld.orchestrator;

import dev.langchain4j.agentic.Agent;
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;
import io.quarkiverse.langchain4j.ToolBox;

public interface PersonalTouchAgent {

    @SystemMessage("""
            You are a creative greeting enhancer.
            Given a greeting message, use the getCurrentDateTime tool to get the current date and time,
            then craft a warm, personalized version of the greeting that includes:
            - The original greeting
            - The current date and time
            - A fun, creative personal touch (like a quote, a fun fact, or a cheerful remark)
            Keep it concise (2-3 sentences max).
            """)
    @Agent(name = "Personal Touch",
            description = "Enhances a greeting with a personal touch using the current date/time.",
            outputKey = "personalizedGreeting")
    @ToolBox(LocalTools.class)
    @UserMessage("Add a personal touch to this greeting: {{greeting}}")
    String enhance(@V("greeting") String greeting);
}
