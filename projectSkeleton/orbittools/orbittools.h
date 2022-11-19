#ifndef ORBITTOOLS_H
#define ORBITTOOLS_H

// TRICKY: Make sure only C++ compiles this.
// When compiled from C or SwiftUI, it is excluded
#ifdef __cplusplus
extern "C" {
#endif

// orbit_to_lla:
// Calculate satellite Lat/Lon/Alt for time "now" using
// input TLE-format orbital data
void orbit_to_lla(	const char* in_tle1,	// TLE (Sat Name)
					const char* in_tle2,	// TLE line 1
					const char* in_tle3,	// TLE line 2
					double* out_tleage,		// age of TLE in secs since: Jan 1, 2001 00h UTC
					double* out_latdegs,	// latitude in degs
					double* out_londegs,	// longitude in degs
					double* out_altkm);		// altitude in km

// orbit_to_lla2:
// Calculate satellite Lat/Lon/Alt plus look-angles
// for time "now" using input TLE-format orbital data
void orbit_to_lla2(	const char* in_tle1,	// TLE (Sat Name)
					const char* in_tle2,	// TLE line 1
					const char* in_tle3,	// TLE line 2
					double in_gpslat,		// my GPS latitude in degs 
					double in_gpslon,		// my GPS longitude in degs
					double in_gpsalt,		// my GPS altitude in km
					double* out_tleage,		// age of TLE in secs since: Jan 1, 2001 00h UTC
					double* out_latdegs,	// latitude in degs
					double* out_londegs,	// longitude in degs
					double* out_altkm,		// altitude in km
					double* out_azdegs,		// look angle azimuth in degs
					double* out_eledegs);	// look angle elevation in degs

#ifdef __cplusplus
} // extern "C"
#endif

#endif // ORBITTOOLS_H
