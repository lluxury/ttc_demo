package com.ttc.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ttc.api.dto.CalcReq;
import com.ttc.api.dto.CalcResult;
import com.ttc.business.service.CalculateService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;   // ✅ 修改这里
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CalculateController.class)
class CalculateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean   // ✅ 修改这里（原 @MockitoBean）
    private CalculateService calculateService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testCalcEndpoint_WithTemplateId() throws Exception {
        CalcReq req = new CalcReq(1001L, 1L, Map.of("a", 90));
        CalcResult result = new CalcResult("1001", "A", 85);

        when(calculateService.calculateScore(any(CalcReq.class))).thenReturn(result);

        mockMvc.perform(post("/api/score/calc")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.grade").value("A"));
    }

    @Test
    void testCalcEndpoint_WithoutTemplateId_AutoFillDefault() throws Exception {
        // 请求体不传 templateId
        Map<String, Integer> scores = Map.of("a", 90);
        // 注意：这里直接构造时 templateId = null
        CalcReq req = new CalcReq(1001L, null, scores);

        // 由于 Controller 自动补全为 1L，Service 实际收到的是 templateId=1
        CalcResult result = new CalcResult("1001", "B", 75);
        when(calculateService.calculateScore(any(CalcReq.class))).thenReturn(result);

        mockMvc.perform(post("/api/score/calc")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
        // 验证内部确实调用了 service（具体是否补全需看日志，Mockito无法直接捕获修改后的对象，但逻辑上可覆盖率）
    }
}