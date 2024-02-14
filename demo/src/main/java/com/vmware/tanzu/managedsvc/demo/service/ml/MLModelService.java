package com.vmware.tanzu.managedsvc.demo.service.ml;


import com.vmware.tanzu.managedsvc.demo.model.MlflowModelVersion;

import java.util.Optional;

public interface MLModelService {
    public Optional<MlflowModelVersion> getActiveModelInfo();

}
