package com.ttc.api.dto;

import org.junit.jupiter.api.Test;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

class DtoTest {

    @Test
    void testCalcReq() {
        Map<String, Integer> scores = Map.of("a", 90, "b", 80);
        CalcReq req = new CalcReq(1001L, 1L, scores);
        assertEquals(1001L, req.employeeId());
        assertEquals(1L, req.templateId());
        assertEquals(2, req.scoreMap().size());
    }

    @Test
    void testCalcResult() {
        CalcResult result = new CalcResult("1001", "A", 85);
        assertEquals("1001", result.employeeId());
        assertEquals("A", result.grade());
        assertEquals(85, result.totalScore());
    }

    @Test
    void testTemplateCreateReq() {
        Map<String, Double> weights = Map.of("w1", 0.4, "w2", 0.6);
        TemplateCreateReq req = new TemplateCreateReq("KPI", 100, weights);
        assertEquals("KPI", req.name());
        assertEquals(100, req.baseScore());
        assertEquals(0.6, req.weights().get("w2"));
    }
}