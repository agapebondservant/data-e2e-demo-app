package com.vmware.tanzu.managedsvc.demo.service.ml.impl;

import com.vmware.tanzu.managedsvc.demo.service.ml.MLModelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;


@Service("MLFLOW")
@Slf4j
@RequiredArgsConstructor
public class MLflowModelService implements MLModelService {

    @Value("${mlmodel.registry}")
    private String mlFlowTrackingServer;

    @Override
    public Map getActiveModelInfo() {
        log.info("MLFlow tracking server...{}", mlFlowTrackingServer);

        return null;
    }
}
