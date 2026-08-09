package com.ttc.common;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ResultTest {

    @Test
    void testSuccess() {
        Result<String> result = Result.success("hello");
        assertEquals(200, result.getCode());
        assertEquals("success", result.getMsg());
        assertEquals("hello", result.getData());
    }

    @Test
    void testError() {
        Result<String> result = Result.error("something wrong");
        assertEquals(500, result.getCode());
        assertEquals("something wrong", result.getMsg());
        assertNull(result.getData());
    }
}