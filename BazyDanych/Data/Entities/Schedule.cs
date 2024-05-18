using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Schedule ID = {Id}, Employee ID = {EmployeeId}, Decision ID = {DecisionId}, Date = {Date}, Start Time = {StartTime}, End Time = {EndTime}")]
public class Schedule
{
    [Column("id_harmonogramu")] public int Id { get; set; }

    [Column("id_pracownika")] public int EmployeeId { get; set; }

    [Column("id_decyzji")] public int DecisionId { get; set; }

    [Column("data")] public DateTime Date { get; set; }

    [Column("czas_rozpoczecia")] public TimeSpan StartTime { get; set; }

    [Column("czas_zakonczenia")] public TimeSpan EndTime { get; set; }
}