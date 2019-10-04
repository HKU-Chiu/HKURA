# This could be a vignette.
#Goal A: Determine common IBSI featureset between projects
#Goal B: Subset cohort data using that information
#Goal C: Wrangle cohort data for plotting with ggplot

library(hku.chiu.hkurla) #ibsidata, ibsicohort, cohortmap
library(tidyverse)

projects = c("cgita", "cerr", "ibex", "mval", "pyradiomics")
varnames = c("index", "projname", "projcat", "ibsi name", "ibsi code") #variables used by each project dataframe
#for ibsi table: ensure col 1-5 *is* Category, Catcode, Catabbrev, ibsi name, ibsi code

#general dataframe from all projects, excluding features that have no IBSI mapping
df = map(ibsidata[projects], function(x){colnames(x) = varnames; return(x)} ) %>%
  bind_rows(.id = "library") %>%
  select(-`ibsi name`) %>%
  inner_join(ibsidata[["ibsi"]], by = "ibsi code") #also adds category code info, just in case

#Determine the common set of IBSI features implemented at least once by each project.
commonID = df %>%
  group_by(`ibsi code`) %>%
  summarize(cnt = length(unique(library))) %>%
  filter(cnt == 5) %>%
  pull(`ibsi code`) #string vector

#subset df
common = df %>% filter(`ibsi code` %in% commonID)

#For each project, get feature identifier corresponding to common IBSI
IDvalues = common %>% group_split(library) %>% map(~ .x$index)
names(IDvalues) = common %>% group_keys(library) %>% pull(library)

#now map each set of n feature IDs to their set of N strings(where N >= n) denoting cohort variables
selectors = imap(IDvalues, function(id, lib){
  m = cohortmap[[lib]]
  IDvar = colnames(m)[2]
  key = setNames("index", IDvar)
  m %>%
    filter(get(IDvar) %in% id) %>%
    left_join(filter(common, library == lib), by = key) %>%
    select(-IDvar)
})

#Merge the 4 datasets into a single dataframe, without nans
ibsicohorts = imap_dfr(cohortdata, function(x, lib){
  varMap = selectors[[lib]]
  selectedVars = c("PatientID", pull(varMap, "MATLAB name"))
  x = x %>%
    select(selectedVars) %>% #subset our data using the N selector strings
    gather(key = "feature", value = "value", -PatientID) %>% #gather the feature variables into a value/factor pair.
    left_join(varMap, by = c("feature" = "MATLAB name")) %>% #Add variable: ibsi code
    na.exclude()
}, .id = "library")

#Add variable: Normalized range by feature/library. Note that outliers will mess up the binning.
ibsicohorts = ibsicohorts %>%
  group_by(feature, library) %>%
  group_modify(~ {
    .x %>%
      mutate(norm.value = (value - min(value)) / (max(value) - min(value)))
  }) %>%
  ungroup()


#Prepare a dataframe for pairwise library comparison.
perms = combn(unique(ibsicohorts$library), 2, simplify = FALSE)
pairdata = ibsicohorts %>%
  distinct(library, `ibsi code`, PatientID, .keep_all = TRUE)
pairdata = map_dfr(perms, function(x){
  a = filter(pairdata, library == x[1])
  b = filter(pairdata, library == x[2])
  return(inner_join(a, b, by = c("PatientID", "ibsi code"))) #bind_cols if you're confident
})

#ICC per feature
iccfeatures = ibsicohorts %>% group_by(`ibsi code`) %>% summarize(icc = ICC::ICCest(library, value, data = .data)$ICC)



