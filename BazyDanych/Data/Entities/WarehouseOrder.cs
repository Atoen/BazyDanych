using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Order ID = {Id}, Ordering Employee ID = {OrderingEmployeeId}, Order Date = {OrderDate}, Total Price = {TotalPrice}")]
public class WarehouseOrder
{
    [Column("id_zamowienia")] public int Id { get; set; }

    [Column("id_pracownika_zamawiajacego")] public int OrderingEmployeeId { get; set; }

    [Column("data_zlozenia")] public DateTime OrderDate { get; set; }

    [Column("data_zrealizowania")] public DateTime? CompletionDate { get; set; }

    [Column("id_pracownika_przyjmujacego")] public int? ReceivingEmployeeId { get; set; }

    [Column("cena_sumaryczna")] public decimal TotalPrice { get; set; }
}