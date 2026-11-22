package br.com.techagro.compras.exceptions.domain;

import org.springframework.validation.BindingResult;

import java.time.LocalDateTime;
import java.util.HashMap;

public class ItemMessage {

    private int statusError;
    private String error;
    private String message;
    private LocalDateTime timestamp;
    private HashMap<String, String> errors;
    private String path;
    private String method;


    public void addErrors(BindingResult result){

    }

}
