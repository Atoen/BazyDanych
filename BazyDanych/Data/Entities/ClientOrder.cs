using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Client Order ID = {Id}, Order Date = {OrderDate}, Total Price = {TotalPrice}")]
public class ClientOrder
{
    [Column("id_zamowienia_klienta")] public int Id { get; set; }

    [Column("data_zlozenia")] public DateTime OrderDate { get; set; }

    [Column("cena_sumaryczna")] public decimal TotalPrice { get; set; }
}