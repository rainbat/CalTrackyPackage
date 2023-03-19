import Foundation
import EventKit
import SwiftyJSON

public struct CalTrackyPackage {
    public private(set) var text = "Hello, World!"

    public init() {
    }
    
    public func fetchEvents() {
        //print("fetching calendar events")
        let eventStore = EKEventStore()
        
        //eventStore.requestAccess(to: .reminder) { granted, error in }
        let calendars = eventStore.calendars(for: .event)
        
        let dateFormatterScript = ISO8601DateFormatter()
        let dateFormatterPrint = DateFormatter()
        let dateFormatterPrintYear = DateFormatter()
        let dateFormatterPrintMonth = DateFormatter()
        let dateFormatterDiff = DateFormatter()
        
        dateFormatterPrint.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatterPrintYear.dateFormat = "yyyy"
        dateFormatterPrintMonth.dateFormat = "MM"
        dateFormatterDiff.dateFormat = "hh"
        
        var MyEvents: [ Dictionary<String, Any> ] = [];
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withDashSeparatorInDate,
            .withFractionalSeconds]
        let output = DateFormatter()
        output.dateFormat = "yyy-MM-dd hh:mm"
        for calendar in calendars {
            //print("... calendar " + calendar.title)
            let fiveYearsAgo = NSDate(timeIntervalSinceNow:   -1 * 4 * 365  * 24 * 3600 )
            //let aMonthAgo = NSDate(timeIntervalSinceNow:   -1 * 30  * 24 * 3600 )
            let oneMonthAfter = NSDate(timeIntervalSinceNow:   1  * 24 * 3600 )
            let predicate = eventStore.predicateForEvents(withStart: fiveYearsAgo as Date, end: oneMonthAfter as Date, calendars: [calendar])
            let events = eventStore.events(matching: predicate)
            for event in events {
                let startDateDate = event.startDate as NSDate;
                let endDateDate = event.endDate as NSDate;
                let duration = endDateDate.timeIntervalSince(startDateDate as Date) as TimeInterval;
                let duration_hours = duration.hoursFromTimeInterval();
                var item_new = JSON();
                // ?.withAddedHours(hours: -2)
                if let isoDateFormatted = isoDateFormatter.date(from: dateFormatterScript.string(from: event.startDate!) )?.withAddedHours(hours: -2) {
                    item_new["start_date"] = JSON( output.string( from: isoDateFormatted ) )
                }
                if let isoDateFormatted = isoDateFormatter.date(from: dateFormatterScript.string(from: event.endDate!) )?.withAddedHours(hours: -2) {
                    item_new["end_date"] = JSON( output.string( from: isoDateFormatted ) )
                }
                if( dateFormatterPrintYear.string(from: event.startDate!) != "2022" ) {
                    //continue
                }
                MyEvents.append([
                    "Calendar": calendar.title,
                    "id": event.calendarItemIdentifier,
                    "Title": event.title as Any,
                    "Year": dateFormatterPrintYear.string(from: event.startDate!),
                    "Month": dateFormatterPrintMonth.string(from: event.startDate!),
                    "Duration": duration,
                    "Duration_Hours": duration_hours,
                    "StartDate" : dateFormatterScript.string(from: event.startDate!),
                    "EndDate" : dateFormatterScript.string(from: event.endDate!),
                    "start_date" :  dateFormatterPrint.string(from: event.startDate!),
                    "end_date" : dateFormatterPrint.string(from: event.endDate!),
                    "Note" : event.notes as Any
                ])
            }
        }
        //let documentDirectoryUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        guard let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier:nil)?.appendingPathComponent("Documents") else { return }
        let fileUrl = iCloudDocumentsURL.appendingPathComponent("calendar-events.json")
        if (!JSONSerialization.isValidJSONObject(MyEvents)) {
            //print("is not a valid json object")
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: MyEvents, options: JSONSerialization.WritingOptions.prettyPrinted)
            try data.write( to: fileUrl, options: [] )
        } catch {}
        //print("finished calendar events")
    }
}

extension TimeInterval{
    
    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
        
    }
    func hoursFromTimeInterval() -> String {
        return String(self/3600)
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var startOfMonth: Date {
        
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        
        return  calendar.date(from: components)!
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
    func isMonday() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday == 2
    }
    
    func startOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.startOfDay(for: self)
    }
    
    func endOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(calendar: calendar))!
    }
    func withAddedMinutes(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }
    func withAddedHours(hours: Double) -> Date {
        withAddedMinutes(minutes: hours * 60)
    }
    func withSubtractedDays(calendar: Calendar = .autoupdatingCurrent) -> Date {
        addingTimeInterval(-365 * 24 * 60 * 60)
    }
}

