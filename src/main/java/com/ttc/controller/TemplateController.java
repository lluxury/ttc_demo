package com.ttc.controller;

import com.ttc.api.dto.TemplateCreateReq;
import com.ttc.common.Result;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.service.TemplateService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/management")
public class TemplateController {

    @Autowired
    private TemplateService templateService;

    /**
     * 手动创建新模板（例如创建“销售KPI”），生成ID=2
     * 注意：项目启动时已经自动创建了ID=1的默认模板
     */
    @PostMapping("/template")
    public Result<KpiTemplateEntity> create(@RequestBody TemplateCreateReq req) {
        return Result.success(templateService.createTemplate(req));
    }
}