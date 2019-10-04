#filter on 22OV and 9ZK5, should be 14 variables spread out over 5 libraries
clin = clinical %>%
  select(Train, PatientID = INFO_PatientName, pcr = MandardOutout212vs34) %>%
  mutate_at("pcr", factor)
#MandardOutput11vs24
cohort = ibsicohorts %>%
  filter(`ibsi code` %in% c("22OV", "9ZK5")) %>%
  select(PatientID, feature, value) %>%
  spread(feature, value) %>%
  inner_join(clin, by = "PatientID")

train = cohort %>%
  filter(Train == 1) %>%
  select(-Train, -PatientID)

test = cohort %>%
  filter(Train == 0) %>%
  select(-Train, -PatientID)


rf = randomForest::randomForest(pcr ~ ., data = train, ntree=1000, mtry=10)
pr = predict(rf, select(test, -pcr), type = "prob")
myroc = pROC::roc(predictor = pr[,1], response = pull(test, pcr))
auc = pROC::auc(myroc) #0.82 with Mandard12v34

gg = pROC::ggroc(myroc) +
  theme_minimal() +
  ggtitle("ROC of pCR signature") +
  geom_segment(aes(x = 1, xend = 0, y = 0, yend = 1), color="grey", linetype="dashed")

  #We recognize our illustrative result may be overfitted, and for research on a clinically relevant radiomics signature one should use more features with a rigorous feature selection method.