#Use NMR metabolomics data to perform data quality
library (tidyverse)
setwd("/Users/sree/Downloads/Coding sample data")
sample <- read_csv("NMR_biomarkers.csv")
sample

sample1 <- sample %>% 
  mutate(id = sub("ResearchInstitutionProjectLabId_" , "" , Sample_id))
head(sample1)
sample2 <- sample %>%
    mutate(id = as.numeric(sub("ResearchInstitutionProjectLabId_" , "" , Sample_id))) %>% 
    select(id, everything())
head(sample2)

#Number of distinct IDs in sample2
sample2 %>% .$id %>% n_distinct()

#Read clinical data of subjects who participated in the NMR metabolomics study
clinical <- read_csv("clinical_data.csv")
clinical

#Number of unique ids on clinical
clinical %>% .$id %>% n_distinct()

#id numbers of those who have any duplicates
clinical %>% 
  group_by(id) %>% 
  tally() %>% 
  filter(n>1)

#Remove any duplicates in clinical
clinical2 <- clinical %>% 
    distinct()
clinical2

#id numbers not in sample2
clinical2 %>% 
  select(id) %>% 
  anti_join(sample2, by = "id")

#Semi join
clinical2 %>% 
  semi_join(sample2, by = "id") %>% 
  nrow()

#Inner join
nmr <- clinical2 %>% 
  inner_join(sample2, by ="id")
count(nmr)

#Number of incident diabetes cases
nmr %>% 
  group_by(incident_diabetes) %>% 
  tally()

#Proportion of subjects developed diabetes during the study
nmr %>% 
  group_by(incident_diabetes) %>% 
  tally() %>% 
  mutate(prop = n /sum(n))


#Calculate percentages of various fatty acids in relation to total fatty acid content
names(nmr)

#Divide seven fatty acid content to express as percentage
fa_conc <- function(x) x / nmr$Total_FA* 100
nmr2 <- nmr %>% 
  mutate_at(vars(Omega_3:DHA) , list(pct=fa_conc)) %>%
  mutate(incident_diabetes = factor(incident_diabetes, labels = c("No" , "Yes")))
names(nmr2)

#Compare the Omega_6_pct b/w those who developed diabetes and those who did not
#Boxplots
nmr2 %>%
  ggplot(aes(x = incident_diabetes, y = Omega_6_pct, fill=incident_diabetes)) +
  geom_boxplot()
#Density plots
nmr2 %>%
  ggplot(aes(x = Omega_6_pct, fill =incident_diabetes )) + 
  geom_density(alpha = 0.5)

#Convert nmr2 to long format
names(nmr2)
nmr2_long <- nmr2 %>% 
  pivot_longer(LA:GlycA, names_to = "variable", values_to = "value")

#Variable which is associated with BMI
nmr2_long %>% 
  ggplot(aes(x = BMI, y = value)) +
  geom_point(shape = ".") +
  geom_smooth(method = "lm") +
  facet_wrap(~ variable, scales = "free")

#Find R-square
nmr2_long %>%
  split(.$variable) %>%
  map(~lm(value ~ BMI, data = .)) %>%
  map(summary) %>%
  map_dbl("r.squared")