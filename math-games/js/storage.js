/**
 * storage.js — localStorage 工具函数
 * 所有游戏数据统一通过此模块读写
 */

const Storage = (() => {
  const PREFIX = 'mathgames_';

  function _key(name) {
    return PREFIX + name;
  }

  function _get(name) {
    try {
      return JSON.parse(localStorage.getItem(_key(name)));
    } catch {
      return null;
    }
  }

  function _set(name, value) {
    localStorage.setItem(_key(name), JSON.stringify(value));
  }

  /**
   * 获取某游戏的最佳记录对象
   * @returns {object|null}
   */
  function getRecord(gameId) {
    return _get('record_' + gameId) || null;
  }

  /**
   * 保存记录，strategy 决定如何比较：
   *   'higher' — 数值越高越好（分数）
   *   'lower'  — 数值越低越好（时间、猜测次数）
   * @param {string} gameId
   * @param {object} data  例如 { value: 42, label: '42分' }
   * @param {'higher'|'lower'} strategy
   * @returns {boolean} 是否破纪录
   */
  function saveRecord(gameId, data, strategy = 'higher') {
    const current = getRecord(gameId);
    let isNew = false;
    if (!current) {
      isNew = true;
    } else if (strategy === 'higher' && data.value > current.value) {
      isNew = true;
    } else if (strategy === 'lower' && data.value < current.value) {
      isNew = true;
    }
    if (isNew) {
      _set('record_' + gameId, { ...data, date: new Date().toLocaleDateString('zh-CN') });
    }
    // 保存历史（最近10局）
    const history = getHistory(gameId);
    history.unshift({ ...data, date: new Date().toLocaleDateString('zh-CN') });
    if (history.length > 10) history.pop();
    _set('history_' + gameId, history);
    return isNew;
  }

  /**
   * 获取近10局历史
   */
  function getHistory(gameId) {
    return _get('history_' + gameId) || [];
  }

  /**
   * 获取所有反馈列表
   */
  function getFeedback() {
    return _get('feedback') || [];
  }

  /**
   * 保存一条反馈
   */
  function saveFeedback(text) {
    const list = getFeedback();
    list.unshift({ text: text.trim(), date: new Date().toLocaleDateString('zh-CN') });
    _set('feedback', list);
  }

  return { getRecord, saveRecord, getHistory, getFeedback, saveFeedback };
})();
