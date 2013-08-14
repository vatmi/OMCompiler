
#pragma once
#include "stdafx.h"
#if defined(__vxworks)
#include "stdafx.h"
#include "Euler.h"
#include "EulerSettings.h"

extern "C" ISolver* createEuler(IMixedSystem* system, ISolverSettings* settings)
{
    return new Euler(system,settings);
}

extern "C" ISolverSettings* createEulerSettings(IGlobalSettings* globalSettings)
{
    return new EulerSettings(globalSettings);
}

#elif defined(SIMSTER_BUILD)

#include "Euler.h"
#include "EulerSettings.h"

/*Simster factory*/
extern "C" void BOOST_EXTENSION_EXPORT_DECL extension_export_euler(boost::extensions::factory_map & fm)
{
    fm.get<ISolver,int,IMixedSystem*, ISolverSettings*>()[1].set<Euler>();
    fm.get<ISolverSettings,int, IGlobalSettings* >()[2].set<EulerSettings>();
}

#elif defined(OMC_BUILD)

#include "Euler.h"
#include "EulerSettings.h"

    /* OMC factory */
    using boost::extensions::factory;

    BOOST_EXTENSION_TYPE_MAP_FUNCTION {
    types.get<std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> > >()
    ["EulerSolver"].set<Euler>();
    types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["EulerSettings"].set<EulerSettings>();
    }

#else
error "operating system not supported"
#endif



   