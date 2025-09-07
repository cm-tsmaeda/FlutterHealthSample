//
//  CoreMotionAggregator.swift
//  Runner
//
//  Created by Tasuku Maeda on 2025/09/07.
//
import UIKit
import CoreMotion

class CoreMotionAggregator {
    private var pedometer: CMPedometer?
    private var pedometerData: [CMPedometerData] = []
    private var dateList: [(start: Date?, end: Date?)] = []
    private var fetchIndex: Int = 0

    init () {
        dateList = [
            (start: parseStringWithTimezone("2025-08-31T00:00:00"),
             end: parseStringWithTimezone("2025-09-01T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-01T00:00:00"),
             end: parseStringWithTimezone("2025-09-02T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-02T00:00:00"),
             end: parseStringWithTimezone("2025-09-03T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-03T00:00:00"),
             end: parseStringWithTimezone("2025-09-04T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-04T00:00:00"),
             end: parseStringWithTimezone("2025-09-05T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-05T00:00:00"),
             end: parseStringWithTimezone("2025-09-06T00:00:00")),
            
            (start: parseStringWithTimezone("2025-09-06T00:00:00"),
             end: parseStringWithTimezone("2025-09-07T00:00:00"))
        ]
    }
    
    // CoreMotionを使った集計
    func fetchPedometerData() {
        pedometerData = []
        fetchIndex = 0
        pedometer = CMPedometer()
        fetchPedometerDataByPeriod(dateListIndex: fetchIndex)
    }
    
    // 実際にアクセスするところ
    private func fetchPedometerDataByPeriod(dateListIndex: Int) {
        let dateSet = dateList[dateListIndex]
        guard let from = dateSet.start,
              let to = dateSet.end else {
            return
        }
        pedometer?.queryPedometerData(from: from, to: to) { [weak self] (data, error) in
            guard let self else { return }
            if let error {
                print("dbg error: \(error.localizedDescription)")
            }
            if let data {
                self.pedometerData.append(data)
            }
            print("dbg data: \(data.debugDescription)")
            self.didFetchPedometerDataByPeriod()
        }
    }
    
    private func didFetchPedometerDataByPeriod() {
        fetchIndex += 1
        if fetchIndex == dateList.count {
            print("dbg fetch completed! ===")
            pedometerData.forEach { data in
                print("\(data.startDate) ~ \(data.endDate), \(data.numberOfSteps)歩, \(String(describing: data.distance))m")
            }
        } else {
            fetchPedometerDataByPeriod(dateListIndex: fetchIndex)
        }
    }
    
    func addTimezoneOffset(_ dateString: String, offset: String = "+09:00") -> String {
        // 既にタイムゾーン情報がある場合はそのまま返す
        if dateString.contains("+") || dateString.contains("Z") {
            return dateString
        }
        
        // ISO8601形式に変換してオフセットを追加
        if dateString.contains("T") {
            return dateString + offset
        } else {
            // スペース区切りの場合はTに変換してオフセット追加
            let isoString = dateString.replacingOccurrences(of: " ", with: "T")
            return isoString + offset
        }
    }
    
    func parseStringWithTimezone(_ dateString: String) -> Date? {
        let stringWithOffset = addTimezoneOffset(dateString, offset: "+09:00")
        print("dbg offset \(stringWithOffset)")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        
        // ミリ秒なしでも試す
        if let date = formatter.date(from: stringWithOffset) {
            return date
        }
        
        // ミリ秒なしのフォーマットで再試行
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: stringWithOffset)
    }
}
