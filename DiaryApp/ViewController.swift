//
//  ViewController.swift
//  DiaryApp
//
//  Created by LeeHsss on 2022/01/10.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionVIew: UICollectionView!
    
    private var diaryList = [Diary]() {
        didSet {
            self.saveDiaryList()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollectionView()
        self.loadDiaryList()
        
        NotificationCenter.default.addObserver(self, selector: #selector(editDiaryNotification(_:)), name: NSNotification.Name("editDiary"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(starDiaryNotification(_:)), name: NSNotification.Name("starDiary"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDiaryNotification(_:)), name: NSNotification.Name("deleteDiary"), object: nil)
    }
    
    private func configureCollectionView() {
        self.collectionVIew.collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionVIew.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionVIew.delegate = self
        self.collectionVIew.dataSource = self
    }
    
    @objc func deleteDiaryNotification(_ notification: Notification) {
        guard let diary = notification.object as? Diary else { return }
        guard let row = self.diaryList.firstIndex(where: { aDiary in
            aDiary.uuid == diary.uuid
        }) else { return }
        self.diaryList.remove(at: row)
        self.collectionVIew.deleteItems(at: [IndexPath.init(row: row, section: 0)])
        self.collectionVIew.reloadData()
    }
    
    @objc func starDiaryNotification(_ notification: Notification) {
        guard let starDiary = notification.object as? [String: Any] else { return }
        guard let diary = starDiary["diary"] as? Diary else { return }
        guard let isStar = starDiary["isStar"] as? Bool else { return }
//        guard let indexPath = starDiary["indexPath"] as? IndexPath else { return }
        
        guard let index = self.diaryList.firstIndex(where: { aDiary in
            aDiary.uuid == diary.uuid
        }) else { return }
        
        self.diaryList[index].isStar = isStar
    }
    
    @objc func editDiaryNotification(_ notification: Notification) {
        guard let diary = notification.object as? Diary else {return}
//        guard let row = notification.userInfo?["indexPath.row"] as? Int else { return }
        
        guard let row = self.diaryList.firstIndex(where: { aDiary in
            aDiary.uuid == diary.uuid
        }) else { return }
        
        self.diaryList[row] = diary
        
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        
        self.collectionVIew.reloadData()
    }
    
    private func loadDiaryList() {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.object(forKey: "diaryList") as? [[String: Any]] else {
            return
        }
        
        
        self.diaryList = data.compactMap {
            guard let uuid = $0["uuid"] as? String else { return nil }
            guard let title = $0["title"] as? String else { return nil }
            guard let contents = $0["contents"] as? String else {return nil}
            guard let date = $0["date"] as? Date else {return nil}
            guard let isStar = $0["isStar"] as? Bool else {return nil}
            
            return Diary(uuid: uuid, title: title, contents: contents, date: date, isStar: isStar)
        }
        
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
    }

    // ?????? ??? ????????????? MARK: ?????? ?????? ?????? ?????? ???
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let writeDiaryViewController = segue.destination as? WriteDiaryViewController {
            writeDiaryViewController.delegate = self
        }
    }
    
    private func saveDiaryList() {
        let data = self.diaryList.map {
            [
                "uuid": $0.uuid,
                "title": $0.title,
                "contents": $0.contents,
                "date": $0.date,
                "isStar": $0.isStar
            ]
        }
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(data, forKey: "diaryList")
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy??? MM??? dd???(EEEEE)"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }

}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.diaryList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiaryCell", for: indexPath) as? DiaryCell else {
            return UICollectionViewCell()
        }
        
        let diary = self.diaryList[indexPath.row]
        cell.titleLabel.text = diary.title
        cell.dateLabel.text = self.dateToString(date: diary.date)
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    // MARK: Cell??? ???????????? ???????????? ????????? ?????? ?????????
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (UIScreen.main.bounds.width / 2) - 20, height: 200)
    }
}

extension ViewController: WriteDiaryViewDelegate {
    //MARK: ?????? ??????
    func didSelectRegister(diary: Diary) {
        self.diaryList.append(diary)
        
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        
        self.collectionVIew.reloadData()
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
        
        let diary = self.diaryList[indexPath.row]
        viewController.diary = diary
        viewController.indexPath = indexPath
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
