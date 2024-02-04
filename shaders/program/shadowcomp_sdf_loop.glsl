{
    ivec3 prevTexCoord0 = texCoord + (1<<j) * camOffset;
    ivec3 prevTexCoord = prevTexCoord0 + ivec3(0, frameCounter % 2 * voxelVolumeSize.y, 0);
    ivec3 prevCoord = prevTexCoord0 / 2 + voxelVolumeSize / 4 + ivec3(0, frameCounter % 2 * voxelVolumeSize.y, 0);
    fullDist[localCoord.x+1][localCoord.y+1][localCoord.z+1] =
        all(greaterThanEqual(prevTexCoord0, ivec3(0))) &&
        all(lessThan(prevTexCoord0, voxelVolumeSize)) ?
        imageLoad(distanceFieldI, prevTexCoord)[j] + 1.0 / (1<<j) : (
            #if j > 0
                max(imageLoad(distanceFieldI, prevCoord)[j-1] - 0.5 / (1<<j), 0.5/(1<<j))
            #else
                1000.0
            #endif
        );
    barrier();
    memoryBarrierShared();
    if (all(greaterThanEqual(localCoord, ivec3(0))) && all(lessThan(localCoord, ivec3(8)))) {
        #if j > 0
            float prevDist = imageLoad(distanceFieldI, prevCoord)[j-1];
            float prevThisLODdist = fullDist[localCoord.x+1][localCoord.y+1][localCoord.z+1] - 1.0/(1<<j);
            if (prevDist < 3.0/(1<<j) || abs(prevThisLODdist - prevDist) > 0.75 / (1<<j) ) {
            #endif
            theseDists[j] = (thisOccupancy >> j & 1) == 1 ? -1.0/sqrt(3.0) / (1<<j) : ((thisOccupancy >> j+5 & 1) == 1 ? 0.5 : 1000);
            #if j > 0
                if (any(lessThan(texCoord, ivec3(1))) || any(greaterThanEqual(texCoord, voxelVolumeSize - 1))) {
                    theseDists[j] = min(theseDists[j], prevDist + 0.25/(1<<j));
                }
            #endif
            /* if (false && j < 3) {
                ivec3 nextCoord = prevTexCoord * 2 - voxelVolumeSize/2;
                if (all(greaterThanEqual(nextCoord, ivec3(0))) && all(lessThan(nextCoord, voxelVolumeSize))) {
                    for (int k = 0; k < 8; k++) {
                        theseDists[j] = min(theseDists[j], imageLoad(distanceFieldI, nextCoord + ivec3(k%2, k/2%2, k/4))[j+1]);
                    }
                }
            } */
            for (int k = 0; k < 27; k++) {
                ivec3 c2 = localCoord + ivec3(k%3, k/3%3, k/9%3);//(k/3*2-1) * ivec3(equal(ivec3(k%3), ivec3(0,1,2))) + 1;//
                theseDists[j] = min(theseDists[j], fullDist[c2.x][c2.y][c2.z]);
            }
        #if j > 0
            } else {
                theseDists[j] = prevDist - 0.5/(1<<j);
            }
        #endif
    }
    barrier();
}
