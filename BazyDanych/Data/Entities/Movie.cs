using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("{MovieName}, Age Category = {AgeCategory}, Tickets Sold = {TicketsSold}, Starts = {StartTime}, Ends = {EndTime}")]
public class Movie
{
    [Column("id_seansu")] public int Id { get; set; }

    [Column("nazwa_filmu")] public string MovieName { get; set; } = null!;

    [Column("kategoria_wiekowa")] public int AgeCategory { get; set; }

    [Column("ilosc_sprzednaych_biletow")] public int TicketsSold { get; set; }

    [Column("czas_rozpoczecia")] public DateTime StartTime { get; set; }

    [Column("czas_zakonczenia")] public DateTime EndTime { get; set; }

    [Column("id_decyzji")] public int? DecisionId { get; set; }
}