package com.vmware.tanzu.managedsvc.demo.service.ml.impl;

import com.vmware.tanzu.managedsvc.demo.model.MlflowModelVersion;
import com.vmware.tanzu.managedsvc.demo.service.ml.MLModelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;


@Service("MLFLOW")
@Slf4j
@RequiredArgsConstructor
public class MLflowModelService implements MLModelService {

    @Value("${mlmodel.registry}")
    private String mlFlowTrackingServer;

    private static final String MODEL_VERSIONS_ENDPOINT = "/api/2.0/mlflow/model-versions/search";

    private final RestTemplate restTemplate;

    public MLflowModelService(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder.build();
    }

    @Override
    public Optional<MlflowModelVersion> getActiveModelInfo() {
        log.info("MLFlow tracking server...{}", mlFlowTrackingServer);

        MlflowModelVersion[] modelVersions =
                this.restTemplate
                        .getForEntity(String.format("%s/%s", mlFlowTrackingServer, MODEL_VERSIONS_ENDPOINT), MlflowModelVersion[].class)
                        .getBody();

        Optional<MlflowModelVersion> activeModelInfo =
                Optional.ofNullable(Arrays.stream(modelVersions)
                        .filter(mv -> mv.getCurrentStage().equals("PRODUCTION"))
                        .findFirst()
                        .orElse(null));

        return activeModelInfo;
    }
}
