import {createHash} from "node:crypto";

const THUMBNAIL_KEY = /^[a-f0-9]{64}$/;

export function visualizationThumbnailKey(workspace: string, animation: string): string {
    return createHash("sha256").update(workspace).update("\0").update(animation).digest("hex");
}

export function validThumbnailKey(value: unknown): value is string {
    return typeof value === "string" && THUMBNAIL_KEY.test(value);
}
