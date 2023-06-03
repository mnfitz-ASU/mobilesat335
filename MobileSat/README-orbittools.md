# NOTES ON HOW TO INTEGRATE ORBITTOOLS SOURCE

Matthew Fitzgerald 11/23/2022

TROUBLE: Had to abandon celestrak because I could never get the `rv2coe()` function to work. 
The Celestrak function `SGP4Funcs::rv2coe()` does not support calculations for `double &arglat, double &truelon, double &lonper`. 
This means that no matter what satellite was called, the return value for latitude and longitude information would be `#define undefined 999999.1`.
This problem persisted even in the Celestrak example tests.

Switched to orbittools library from zeptomoby (written in C++).
The unit tests in orbittools produced the correct results, so I have decided to utilize orbittools.
Example usage (From their demo program): 
```
{
    // Test SGP4 TLE data
   string str1 = "SGP4 Test";
   string str2 = "1 88888U          80275.98708465  .00073094  13844-3  66816-4 0     8";
   string str3 = "2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518   105";

    // Create a TLE object using the data above
   cTle tleSDP4(str1, str2, str3);

   // Create a satellite object from the TLE object
   cSatellite satSDP4(tleSDP4);

   // Print the position and velocity information of the satellite
   PrintPosVel(satSDP4);

   printf("Example output:\n");

   // Example: Define a location on the earth, then determine the look-angle
   // to the SDP4 satellite defined above.

   // Get the location of the satellite. The earth-centered inertial (ECI)
   // information is placed into eciSDP4.
   // Here we ask for the location of the satellite 90 minutes after
   // the TLE epoch.
   cEciTime eciSDP4 = satSDP4.PositionEci(90.0);

   // Now create a site object. Site objects represent a location on the 
   // surface of the earth. Here we arbitrarily select a point on the
   // equator.
   cSite siteEquator(0.0, -100.0, 0); // 0.00 N, 100.00 W, 0 km altitude

   // Now get the "look angle" from the site to the satellite. 
   // Note that the ECI object "eciSDP4" contains a time associated
   // with the coordinates it contains; this is the time at which
   // the look angle is valid.
   cTopo topoLook = siteEquator.GetLookAngle(eciSDP4);

   // Print out the results.
   printf("AZ: %.3f  EL: %.3f\n", 
          topoLook.AzimuthDeg(),
          topoLook.ElevationDeg());
}
```

Matthew Fitzgerald 11/14/2022

Issue: SGP4 and SGP4TJK seem to be different versions of the same source
SGP4 is the newer version. 
SGP4TJK is 4 years older than SGP4.

Notable Differences:
- Struct `elsetrec::satnum` converted from `long int` to `char[6]`
- Renamed `elsetrec::mu` to `elsetrec::mus`
- Function `sgp4init()` input parameter changed from `const int` to `const char[9]` 
- Changed several public functions naming schemes from `func()` to `func_SGP4()`

Example Usecase
```
void CalcLatLon(double inMeanMotion, double inEccentricity, ... double* outLat, double* outLon)
{
    // Initialize SGP4 with a satrec that's been pre-initialized 
    satrec.jdsatepoch = 2453911.0;
    satrec.jdsatepochF = 0.8321544402;
    satrec.no_kozai = 2.00491383;
    ...
    SGP4Funcs::sgp4init(whichconst, opsmode, satrec.satnum, satrec.jdsatepoch + satrec.jdsatepochF - 2433281.5, satrec.bstar,
        satrec.ndot, satrec.nddot, satrec.ecco, satrec.argpo, satrec.inclo, satrec.mo, satrec.no_kozai,
        satrec.nodeo, satrec);
        
    // jday(): this procedure finds the julian date given the year, month, day, and time.
    SGP4Funcs::jday_SGP4(year, mon, day, hr, minute, sec, jd, jdFrac);
    
    double total = jd + jdFrac;
    
    // set start/stop times for propagation (using jday from above)
    startmfe = 0.0;
    stopmfe = 2880.0;
    deltamin = 120.0;
    
    while (tsince < stopmfe) && (satrec.error == 0)
    {
        tsince = tsince + deltamin;

        if (tsince > stopmfe)
            tsince = stopmfe;

        // this procedure is the sgp4 prediction model from space command.
        SGP4Funcs::sgp4(satrec, tsince, ro, vo);

        jd = satrec.jdsatepoch;
        jdFrac = satrec.jdsatepochF + tsince / 1440.0;
        if (jdFrac < 0.0)
        {
            jd = jd - 1.0;
            jdFrac = jdFrac - 1.0;
        }
        
        // this procedure finds the year, month, day, hour, minute and second given the julian date.
        SGP4Funcs::invjday_SGP4(jd, jdFrac, year, mon, day, hr, min, sec);

        // this function finds the classical orbital elements given the geocentric equatorial position and velocity vectors.
        SGP4Funcs::rv2coe_SGP4(ro, vo, satrec.mus, p, a, ecc, incl, node, argp, nu, m, arglat, truelon, lonper);
        
        //arglat, truelon, lonper are the values I want
    }
}

```

