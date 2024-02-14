package com.vmware.tanzu.managedsvc.demo.controllers;

import com.vmware.tanzu.managedsvc.demo.enums.MLModelType;
import com.vmware.tanzu.managedsvc.demo.service.ml.MLModelService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.ObjectUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;

@RestController
@RequestMapping("/mlmodel")
@RequiredArgsConstructor
@Slf4j
public class MLModelController {

    @Autowired
    @Qualifier("MLFLOW")
    private MLModelService mlModelService;

    @GetMapping
    public @ResponseBody ResponseEntity<?> getActiveModelInfo() {
        log.info("Getting active production model... ");
        Object response = ObjectUtils.defaultIfNull( mlModelService.getActiveModelInfo().get(), Collections.EMPTY_MAP );
        return ResponseEntity.ok(response);
    }
}
