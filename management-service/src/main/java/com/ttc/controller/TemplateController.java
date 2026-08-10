package com.ttc.controller;

import com.ttc.api.dto.TemplateCreateReq;
import com.ttc.common.Result;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.service.TemplateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/template")
public class TemplateController {

    @Autowired
    private TemplateService templateService;

    // 创建模板（Post）
    @PostMapping
    public Result<KpiTemplateEntity> create(@RequestBody TemplateCreateReq req) {
        return Result.success(templateService.createTemplate(req));
    }

    // 根据 ID 查询模板（Get）—— 供 business-service 远程调用
    @GetMapping("/{id}")
    public Result<KpiTemplateEntity> getTemplate(@PathVariable Long id) {
        return Result.success(templateService.getTemplate(id));
    }
}