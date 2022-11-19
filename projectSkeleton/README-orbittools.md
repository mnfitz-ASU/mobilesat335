# NOTES ON HOW TO INTEGRATE CELESTRAK SOURCE

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

