package org.a2aproject.example.helloworld.orchestrator;

import dev.langchain4j.agentic.declarative.Output;
import dev.langchain4j.agentic.declarative.SequenceAgent;
import dev.langchain4j.service.UserMessage;
import dev.langchain4j.service.V;

public interface GreetingWorkflow {

    @SequenceAgent(
            outputKey = "greetingResult",
            subAgents = {HelloWorldRemoteAgent.class, PersonalTouchAgent.class})
    @UserMessage("Greet {{name}}")
    GreetingResult processGreeting(@V("name") String name);

    @Output
    static GreetingResult output(String greeting, String personalizedGreeting) {
        return new GreetingResult(greeting, personalizedGreeting);
    }
}
