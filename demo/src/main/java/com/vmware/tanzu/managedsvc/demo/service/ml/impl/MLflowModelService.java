package com.vmware.tanzu.managedsvc.demo.service.ml.impl;

import com.vmware.tanzu.managedsvc.demo.model.MlflowModelVersion;
import com.vmware.tanzu.managedsvc.demo.model.MlflowModelVersionList;
import com.vmware.tanzu.managedsvc.demo.service.ml.MLModelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;


@Service("MLFLOW")
@Slf4j
@RequiredArgsConstructor
public class MLflowModelService implements MLModelService {

    @Value("${mlmodel.registry}")
    private String mlFlowTrackingServer;

    private RestTemplate restTemplate = new RestTemplate();

    private static final String MODEL_VERSIONS_ENDPOINT = "/api/2.0/mlflow/model-versions/search";

    private static final String PRODUCTION_STAGE = "PRODUCTION";

    @Override
    public Optional<MlflowModelVersion> getActiveModelInfo() {
        log.info("MLFlow tracking server endpoint..." + String.format("%s/%s", mlFlowTrackingServer, MODEL_VERSIONS_ENDPOINT));

        MlflowModelVersionList modelVersionList =
                restTemplate
                        .getForEntity(String.format("%s/%s", mlFlowTrackingServer, MODEL_VERSIONS_ENDPOINT), MlflowModelVersionList.class)
                        .getBody();

        log.debug("modelVersionList..." + modelVersionList);

        List<MlflowModelVersion> modelVersions = modelVersionList.getModelVersions();

        Optional<MlflowModelVersion> activeModelInfo =
                modelVersions.stream()
                        .filter(mv -> mv.getCurrentStage().equalsIgnoreCase(PRODUCTION_STAGE))
                        .findFirst();

        log.info("activeModelInfo..." + activeModelInfo.orElse(null));

        return activeModelInfo;
    }
}
