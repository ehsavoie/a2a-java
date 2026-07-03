package org.a2aproject.example.helloworld.orchestrator;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/greet")
public class GreetingResource {

    @Inject
    GreetingWorkflow greetingWorkflow;

    @GET
    @Path("/{name}")
    @Produces(MediaType.APPLICATION_JSON)
    public GreetingResult greet(@PathParam("name") String name) {
        return greetingWorkflow.processGreeting(name);
    }
}
