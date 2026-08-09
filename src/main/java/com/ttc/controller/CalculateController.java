package com.ttc.controller;

import com.ttc.api.dto.CalcReq;
import com.ttc.api.dto.CalcResult;
import com.ttc.business.service.CalculateService;
import com.ttc.common.Result;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/score")
public class CalculateController {

    @Autowired
    private CalculateService calculateService;

    @PostMapping("/calc")
    public Result<CalcResult> calc(@RequestBody CalcReq req) {
        // 自动补全默认模板ID=1（启动时自动生成的）
        if (req.templateId() == null) {
            req = new CalcReq(req.employeeId(), 1L, req.scoreMap());
        }
        CalcResult result = calculateService.calculateScore(req);
        return Result.success(result);
    }
}