namespace BazyDanych.Data.Models;

public record StatusMessageData(string Text, StatusMessageType Type)
{
    public bool IsNullOrEmpty => string.IsNullOrEmpty(Text);

    public override string ToString() => Text;
}

public enum StatusMessageType
{
    Info,
    Warning,
    Error
}