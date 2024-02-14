package com.vmware.tanzu.managedsvc.demo.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;

@Getter
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class MlflowModelVersion {
    private String name;
    private String version;
    private String currentStage;
}
