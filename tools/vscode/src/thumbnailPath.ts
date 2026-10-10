export function thumbnailSidecarPath(animation: string): string {
    return /\.lua$/i.test(animation) ? `${animation.slice(0, -4)}.gif` : `${animation}.gif`;
}
