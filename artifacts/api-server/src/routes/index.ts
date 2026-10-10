import { Router, type IRouter } from "express";
import healthRouter from "./health";
import audioRouter from "./audio";

const router: IRouter = Router();

router.use(healthRouter);
router.use(audioRouter);

export default router;
