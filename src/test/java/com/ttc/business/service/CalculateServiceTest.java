package com.ttc.business.service;

import com.ttc.api.dto.CalcReq;
import com.ttc.api.dto.CalcResult;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.service.TemplateService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CalculateServiceTest {

    @Mock
    private TemplateService templateService;

    @InjectMocks
    private CalculateService calculateService;

    private KpiTemplateEntity template;
    private Map<String, Double> weights;

    @BeforeEach
    void setUp() {
        // 准备一个模板权重（英文键，与请求匹配）
        weights = Map.of("codeQuality", 0.4, "responseSpeed", 0.3, "teamwork", 0.3);
        template = new KpiTemplateEntity();
        template.setId(1L);
        template.setName("DevKPI");
        template.setWeights("{\"codeQuality\":0.4,\"responseSpeed\":0.3,\"teamwork\":0.3}");
        template.setBaseScore(100);
    }

    @Test
    void testCalculateScore_Success_A() {
        when(templateService.getTemplate(1L)).thenReturn(template);

        Map<String, Integer> scores = Map.of("codeQuality", 95, "responseSpeed", 80, "teamwork", 70);
        CalcReq req = new CalcReq(1001L, 1L, scores);

        CalcResult result = calculateService.calculateScore(req);

        assertNotNull(result);
        assertEquals("1001", result.employeeId());
        assertEquals(83, result.totalScore());  // 95*0.4 + 80*0.3 + 70*0.3 = 83
        assertEquals("A", result.grade());      // 83/10=8 -> A
    }

    @Test
    void testCalculateScore_Success_S() {
        when(templateService.getTemplate(1L)).thenReturn(template);

        Map<String, Integer> scores = Map.of("codeQuality", 98, "responseSpeed", 95, "teamwork", 92);
        CalcReq req = new CalcReq(1001L, 1L, scores);

        CalcResult result = calculateService.calculateScore(req);
        // 98*0.4 + 95*0.3 + 92*0.3 = 39.2 + 28.5 + 27.6 = 95.3 -> 取整95，等级S
        assertEquals(94, result.totalScore());
        assertEquals("S", result.grade());
    }

    @Test
    void testCalculateScore_WithMissingWeight_DefaultsToZero() {
        // 注意这个模板只有 codeQuality 和 responseSpeed，没有 teamwork
        String partialWeights = "{\"codeQuality\":0.5,\"responseSpeed\":0.5}";
        template.setWeights(partialWeights);
        when(templateService.getTemplate(1L)).thenReturn(template);

        // 请求包含了 teamwork，但权重中缺失，应忽略
        Map<String, Integer> scores = Map.of("codeQuality", 100, "responseSpeed", 80, "teamwork", 100);
        CalcReq req = new CalcReq(1001L, 1L, scores);

        CalcResult result = calculateService.calculateScore(req);
        assertEquals(90, result.totalScore()); // 100*0.5 + 80*0.5 + 100*0 = 90
        assertEquals("S", result.grade());     // 90 -> A
    }

    @Test
    void testCalculateScore_TemplateNotFound_ThrowsException() {
        when(templateService.getTemplate(999L)).thenReturn(null);

        CalcReq req = new CalcReq(1001L, 999L, Map.of("a", 10));

        Exception exception = assertThrows(RuntimeException.class, () -> {
            calculateService.calculateScore(req);
        });
        assertEquals("模板不存在", exception.getMessage());
    }

    @Test
    void testCalculateScore_LowScore_GradeD() {
        when(templateService.getTemplate(1L)).thenReturn(template);

        Map<String, Integer> scores = Map.of("codeQuality", 50, "responseSpeed", 40, "teamwork", 30);
        CalcReq req = new CalcReq(1001L, 1L, scores);

        CalcResult result = calculateService.calculateScore(req);
        // 50*0.4 + 40*0.3 + 30*0.3 = 20 + 12 + 9 = 41
        assertEquals(41, result.totalScore());
        assertEquals("D", result.grade()); // 41/10=4 -> default D
    }
}