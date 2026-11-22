package br.com.techagro.compras.exceptions;

public class BusinessException extends RuntimeException {

    public BusinessException() {
        super("Business exception ocurred");
    }

    public BusinessException(String message) {
        super(message);
    }
}

