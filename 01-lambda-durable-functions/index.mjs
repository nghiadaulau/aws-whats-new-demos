import { withDurableExecution } from "@aws/durable-execution-sdk-js";

export const handler = withDurableExecution(async (event, context) => {
  const message = await context.step("greet", (stepCtx) => {
    stepCtx.logger.info("STEP greet running");
    return "Hello from a durable function!";
  });

  // Tam dung 10s, KHONG ton compute trong luc cho
  await context.wait({ seconds: 10 });

  // Replay-aware: chi log MOT lan du ham replay sau khi cho
  context.logger.info("RESUMED after wait");

  return { statusCode: 200, body: message };
});
